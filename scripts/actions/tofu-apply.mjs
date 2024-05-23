import path from "node:path";
import fs from "node:fs/promises";
import os from "node:os";
import { Buffer } from "node:buffer";
import { Logger } from "./util/logger.mjs";

/**
 * Download the last successful tofu plan associated with this pull request
 *
 * @param {import("github-script").AsyncFunctionArguments} ctx
 */
export const downloadTofuPlan = async ({
	github,
	context,
	core,
	glob,
	io,
	exec,
	require,
}) => {
	Logger.init(core);

	const lastTenCheckruns = await getLastTenCheckruns({ github, context });
	const runId = getLastSuccessfulTofuPlanWorkflowRunId(lastTenCheckruns);
	const zippedTofuPlanData = await downloadWorkflowArtifact({
		github,
		context,
		runId,
	});
	const tofuPlanPath = await extractTofuPlanFromArchive({
		zippedTofuPlanData,
		exec,
		io,
		context,
	});

	Logger.log(`Tofu plan file is available at ${tofuPlanPath}. Success!`);
	return tofuPlanPath;
};

/**
 * Retrieve the last 10 checkruns (i.e. workflows) that ran on this pull request.
 *
 * @param {Pick<import("github-script").AsyncFunctionArguments, "github" | "context">} ctx
 */
const getLastTenCheckruns = async ({ github, context }) => {
	const pullRequestNumber = context.payload.pull_request?.number;

	if (typeof pullRequestNumber !== "number") {
		throw new Error("Failed to determine PR number");
	} else {
		Logger.log(`Getting last 10 checkruns for PR #${pullRequestNumber}`);
	}

	/**
	 * @type {{
	 * 	repository: {
	 *  	pullRequest: {
	 *    	statusCheckRollup: {
	 *      	contexts: {
	 *        	nodes: {
	 *          	name: string;
	 *            conclusion: "FAILURE" | "SUCCESS" | "SKIPPED";
	 *            startedAt: string;
	 *            checkSuite: {
	 *            	workflowRun: {
	 *              	databaseId: number;
	 *              }
	 *            }
	 *          }[]
	 *        }
	 *     	}
	 *    }
	 * 	}
	 * }}
	 */
	const response = await github.graphql(
		`
    query lastTenWorkflowRuns($pullRequestNumber:Int!){
  repository(owner: "swagLGBT", name: "swagLGBT") {
    pullRequest(number: $pullRequestNumber) {
      statusCheckRollup {
        contexts(last: 10) {
          nodes {
            ...on CheckRun{
              name
              conclusion
              startedAt
              checkSuite{
                workflowRun {
                  databaseId
                }
              }
            }
          }
        }
      }
    }
  }
}
    `,
		{ pullRequestNumber },
	);

	Logger.debug(`Response: ${JSON.stringify(response, null, 2)}`);

	return response.repository.pullRequest.statusCheckRollup.contexts.nodes;
};

/**
 * Get the last successful checkrun from this pull request that was a successful Tofu Plan
 *
 * @param {{
 *	name: string;
 *  conclusion: "FAILURE" | "SUCCESS" | "SKIPPED";
 *  startedAt: string;
 *  checkSuite: {
 *  	workflowRun: {
 *    	databaseId: number;
 *    }
 *  }
 * }[]} checkruns
 */
const getLastSuccessfulTofuPlanWorkflowRunId = (checkruns) => {
	const DESIRED_CONCLUSION = "SUCCESS";
	const CHECKRUN_NAME = "Validate & Plan OpenTofu Changes";

	Logger.debug(
		`Attempting to find checkrun with name "${CHECKRUN_NAME}" and conclusion "${DESIRED_CONCLUSION}`,
	);

	const lastSuccessfulTofuPlanWorkflowRun = checkruns
		.filter(
			({ name, conclusion }) =>
				conclusion === DESIRED_CONCLUSION && name === CHECKRUN_NAME,
		)
		.reduce((a, b) => {
			let aTimestamp = Date.parse(a.startedAt);
			let bTimestamp = Date.parse(b.startedAt);
			return aTimestamp > bTimestamp ? a : b;
		});

	Logger.log(
		`Found successful tofu plan:\n${JSON.stringify(lastSuccessfulTofuPlanWorkflowRun, null, 2)}`,
	);

	return lastSuccessfulTofuPlanWorkflowRun.checkSuite.workflowRun.databaseId;
};

/**
 * Download an artifact named `tofu-plan` from a given workflow run
 *
 * @param {Pick<import("github-script").AsyncFunctionArguments, "github" | "context"> & { runId: number }} ctx
 */
const downloadWorkflowArtifact = async ({ github, context, runId }) => {
	Logger.debug(`Finding workflow run artifacts for runId: ${runId}`);

	const {
		data: { artifacts },
	} = await github.rest.actions.listWorkflowRunArtifacts({
		name: "tofu-plan",
		run_id: runId,
		...context.repo,
	});

	if (artifacts.length === 0) {
		throw new Error(`No artifacts found for workflow run ${runId}`);
	} else {
		Logger.debug(
			`Found ${artifacts.length} artifacts:\n${JSON.stringify(artifacts, null, 2)}`,
		);
	}

	const ARTIFACT_NAME = "tofu-plan";

	Logger.debug(`Finding artifact with name "${ARTIFACT_NAME}"`);

	const tofuPlanArtifact = artifacts.find(({ name }) => name === ARTIFACT_NAME);
	if (tofuPlanArtifact === undefined) {
		throw new Error(`No artifact named "${ARTIFACT_NAME}"`);
	} else {
		Logger.debug(
			`Found artifact named "${ARTIFACT_NAME}":\n${JSON.stringify(tofuPlanArtifact, null, 2)}`,
		);
	}

	const tofuPlanArtifactId = tofuPlanArtifact.id;

	Logger.debug(
		`Finding download URL for artifact with id: ${tofuPlanArtifactId}`,
	);

	const { url: artifactUrl } = await github.rest.actions.downloadArtifact({
		artifact_id: tofuPlanArtifactId,
		archive_format: "zip",
		...context.repo,
	});

	Logger.log(
		`Downloading artifact ${tofuPlanArtifactId} ("${ARTIFACT_NAME}") from ${artifactUrl}`,
	);

	const artifactResponse = await fetch(artifactUrl);
	if (!artifactResponse.ok) {
		Logger.error(
			`HTTP Error attempting to download artifact ${tofuPlanArtifactId}: (${artifactResponse.status} ${artifactResponse.statusText})`,
		);
	}
	Logger.debug(`Response:\n${JSON.stringify(artifactResponse, null, 2)}`);

	const contentLength = artifactResponse.headers.get("Content-Length");
	const zippedArtifactData = await artifactResponse.arrayBuffer();

	if (!contentLength) {
		Logger.warn(
			`No Content-Length header sent back from GitHub, ZIP file may be invalid...`,
		);
	} else if (parseInt(contentLength) !== zippedArtifactData.byteLength) {
		Logger.error(
			`Expected ZIP archive to be ${contentLength} bytes, but only found ${zippedArtifactData.byteLength}`,
		);
	} else {
		Logger.log(`Downloaded ${contentLength} bytes`);
	}

	return zippedArtifactData;
};

/**
 * Given an in-memory ZIP archive of a tofu plan, extract the plan file and return the path to it.
 *
 * @param {Pick<import("github-script").AsyncFunctionArguments, "exec" | "io" | "context"> & {zippedTofuPlanData: ArrayBuffer }} args
 */
const extractTofuPlanFromArchive = async ({
	zippedTofuPlanData,
	exec,
	io,
	context,
}) => {
	const tempDirPath = path.resolve(
		os.tmpdir(),
		`tofu-plan-${context.payload.pull_request?.number}`,
	);
	await io.mkdirP(tempDirPath);
	const zipFilePath = path.join(tempDirPath, "tofu-plan.zip");
	const unzippedDirPath = path.join(tempDirPath, "tofu-plan-unzipped");
	await io.mkdirP(unzippedDirPath);

	Logger.debug(`Writing ZIP archive to ${zipFilePath}`);
	await fs.writeFile(zipFilePath, Buffer.from(zippedTofuPlanData));

	// `unzip` is included in the ubuntu runners
	const unzip = await io.which("unzip", true);
	const unzipArgs = [zipFilePath, "-d", unzippedDirPath];
	Logger.debug(
		`Extracting ZIP archive from ${zipFilePath} to ${unzippedDirPath} with command \`${unzip} ${unzipArgs.join(" ")}\``,
	);

	const exitCode = await exec.exec(unzip, unzipArgs);
	if (exitCode !== 0) {
		throw new Error(`Unzipping failed with non-zero exit code ${exitCode}`);
	} else {
		Logger.debug(`Successfully extracted ZIP archive to ${unzippedDirPath}`);
	}

	const files = await fs.readdir(unzippedDirPath);
	if (files.length !== 1) {
		throw Error(
			`Expected to find exactly one file in ${unzippedDirPath}, but found ${files.length}:\n${JSON.stringify(files)}`,
		);
	} else {
		const UNZIPPED_PLAN_FILE_PATH = path.join(unzippedDirPath, files[0]);

		Logger.log(`Extracted tofu plan file to ${UNZIPPED_PLAN_FILE_PATH}`);
		return UNZIPPED_PLAN_FILE_PATH;
	}
};
