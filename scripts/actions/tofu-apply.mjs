import { Buffer } from "node:buffer";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

import * as Logger from "./util/logger.mjs";

/**
 * Retrieve the last 10 checkruns (i.e. workflows) that ran on this pull request.
 *
 * @param {Pick<import("github-script").AsyncFunctionArguments, "github" | "context">} ctx
 */
const getLastTenCheckruns = async ({ github, context }) => {
	const pullRequestNumber = context.payload.pull_request?.number;

	if (typeof pullRequestNumber === "number") {
		Logger.log(`Getting last 10 checkruns for PR #${pullRequestNumber}`);
	} else {
		throw new Error("Failed to determine PR number");
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

	Logger.debug(`Response: ${JSON.stringify(response, null, "  ")}`);

	return response.repository.pullRequest.statusCheckRollup.contexts.nodes;
};

/**
 * Get the last successful checkrun from this pull request with a given checkrun name
 *
 * @param {{
 * 	checkruns: {
 *		name: string;
 *  	conclusion: "FAILURE" | "SUCCESS" | "SKIPPED";
 *  	startedAt: string;
 *  	checkSuite: {
 *  		workflowRun: {
 *  	  	databaseId: number;
 *  	  }
 *  	}
 * 	}[]
 * 	tofuPlanCheckrunName: string;
 * }} checkruns
 */
const getLastSuccessfulTofuPlanWorkflowRunId = ({
	checkruns,
	tofuPlanCheckrunName,
}) => {
	const lastSuccessfulTofuPlanWorkflowRun = checkruns
		.filter(
			({ name, conclusion }) =>
				conclusion === "SUCCESS" && name === tofuPlanCheckrunName,
		)
		.reduce((runA, runB) => {
			const aTimestamp = Date.parse(runA.startedAt);
			const bTimestamp = Date.parse(runB.startedAt);
			return aTimestamp > bTimestamp ? runA : runB;
		});

	Logger.log(
		`Found successful tofu plan:
		${JSON.stringify(lastSuccessfulTofuPlanWorkflowRun, null, "  ")}`,
	);

	return lastSuccessfulTofuPlanWorkflowRun.checkSuite.workflowRun.databaseId;
};

/**
 * Get the download URL for a workflow artifact with a given name from a given workflow run
 *
 * @param {Pick<import("github-script").AsyncFunctionArguments, "github" | "context"> & {
 * 	runId: number;
 *  artifactName: string;
 * }} ctx
 */
const getWorkflowArtifactDownloadUrl = async ({
	github,
	context,
	runId,
	artifactName,
}) => {
	Logger.debug(
		`Finding workflow run artifacts for runId ${runId} named "${artifactName}"`,
	);

	const {
		data: { artifacts },
	} = await github.rest.actions.listWorkflowRunArtifacts({
		name: artifactName,
		// eslint-disable-next-line camelcase
		run_id: runId,
		...context.repo,
	});

	if (artifacts.length !== 1) {
		throw new Error(
			`Expected exactly one artifact named "${artifactName}" for workflow run ${runId}, \
			found ${artifacts.length}`,
		);
	}

	const [{ id: tofuPlanArtifactId }] = artifacts;

	Logger.debug(
		`Finding download URL for artifact with id: ${tofuPlanArtifactId}`,
	);

	const { url } = await github.rest.actions.downloadArtifact({
		// eslint-disable-next-line camelcase
		archive_format: "zip",
		// eslint-disable-next-line camelcase
		artifact_id: tofuPlanArtifactId,
		...context.repo,
	});

	return url;
};

/**
 * Download a zip file and verify its Content-Length matches what we expect
 *
 * @param {string} url
 */
const downloadZipFile = async (url) => {
	const artifactResponse = await globalThis.fetch(url);
	if (!artifactResponse.ok) {
		Logger.error(
			`HTTP Error attempting to download archive from ${url}: \
			(${artifactResponse.status} ${artifactResponse.statusText}).
			
			${JSON.stringify(artifactResponse, null, "  ")}`,
		);
	}

	const zippedArtifactData = await artifactResponse.arrayBuffer();

	const contentLengthHeaderValue =
		artifactResponse.headers.get("Content-Length");

	if (contentLengthHeaderValue === null) {
		Logger.debug("Didn't receive Content-Length header in response");
	} else if (
		parseInt(contentLengthHeaderValue, 10) === zippedArtifactData.byteLength
	) {
		Logger.log(`Downloaded ${contentLengthHeaderValue} bytes`);
	} else {
		Logger.error(
			`Expected ZIP archive to be ${contentLengthHeaderValue} bytes, \
			but only found ${zippedArtifactData.byteLength}`,
		);
	}

	return zippedArtifactData;
};

/**
 * Unzip a file located at zipFilePath into the output directory at outputDirectoryPath
 *
 * @param {Pick<import("github-script").AsyncFunctionArguments, "exec" | "io"> & {
 * 	zipFilePath: string;
 *  outputDirectoryPath: string;
 *  }} args
 */
const unzip = async ({ zipFilePath, outputDirectoryPath, io, exec }) => {
	// `unzip` is included in the ubuntu runners
	const unzipBinary = await io.which("unzip", true);
	const unzipArgs = [zipFilePath, "-d", outputDirectoryPath];
	Logger.debug(
		`Extracting ZIP archive from ${zipFilePath} to ${outputDirectoryPath} \
		with command \`${unzipBinary} ${unzipArgs.join(" ")}\``,
	);

	const exitCode = await exec.exec(unzipBinary, unzipArgs);
	if (exitCode === 0) {
		Logger.debug(
			`Successfully extracted ZIP archive to ${outputDirectoryPath}`,
		);
	} else {
		throw new Error(`Unzipping failed with non-zero exit code ${exitCode}`);
	}
};

/**
 * Given an in-memory ZIP archive of a tofu plan, extract the plan file and return the path to it.
 *
 * @param {Pick<import("github-script").AsyncFunctionArguments, "io" | "context">} args
 */
const createTempDirs = async ({ context, io }) => {
	const parentDirPath = path.resolve(
		os.tmpdir(),
		`tofu-plan-${context.payload.pull_request?.number}`,
	);
	await io.mkdirP(parentDirPath);

	const zipFilePath = path.join(parentDirPath, "tofu-plan.zip");

	const outputDirectoryPath = path.join(parentDirPath, "tofu-plan-unzipped");
	await io.mkdirP(outputDirectoryPath);

	return { outputDirectoryPath, zipFilePath };
};

/**
 * Given an in-memory ZIP archive of a tofu plan, extract the plan file and return the path to it.
 *
 * @param {Pick<import("github-script").AsyncFunctionArguments, "exec" | "io" | "context"> & {
 * 	zippedTofuPlanData: ArrayBuffer
 * }} args
 */
const extractTofuPlanZipArchive = async ({
	zippedTofuPlanData,
	exec,
	io,
	context,
}) => {
	const { zipFilePath, outputDirectoryPath } = await createTempDirs({
		context,
		io,
	});

	Logger.debug(`Writing ZIP archive to ${zipFilePath}`);
	await fs.writeFile(zipFilePath, Buffer.from(zippedTofuPlanData));

	await unzip({ exec, io, outputDirectoryPath, zipFilePath });

	const files = await fs.readdir(outputDirectoryPath);
	if (files.length === 1) {
		const unzippedPlanFilePath = path.join(outputDirectoryPath, files[0]);

		Logger.log(`Extracted tofu plan file to ${unzippedPlanFilePath}`);
		return unzippedPlanFilePath;
	}

	throw Error(
		`Expected to find exactly one file in ${outputDirectoryPath}, but found ${files.length}:
		${JSON.stringify(files)}`,
	);
};

/**
 * Download the last successful tofu plan associated with this pull request
 *
 * @param {import("github-script").AsyncFunctionArguments} ctx
 */
export const downloadTofuPlan = async ({ github, context, core, io, exec }) => {
	Logger.init(core);

	const checkruns = await getLastTenCheckruns({ context, github });
	const runId = getLastSuccessfulTofuPlanWorkflowRunId({
		checkruns,
		tofuPlanCheckrunName: "Validate & Plan OpenTofu Changes",
	});
	const tofuPlanDownloadUrl = await getWorkflowArtifactDownloadUrl({
		artifactName: "tofu-plan",
		context,
		github,
		runId,
	});
	const zippedTofuPlanData = await downloadZipFile(tofuPlanDownloadUrl);
	const tofuPlanPath = await extractTofuPlanZipArchive({
		context,
		exec,
		io,
		zippedTofuPlanData,
	});

	Logger.log(`Tofu plan file is available at ${tofuPlanPath}. Success!`);
	return tofuPlanPath;
};
