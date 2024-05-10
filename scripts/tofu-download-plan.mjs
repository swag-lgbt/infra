import path from "node:path";
import process from "node:process";
import fs from "node:fs/promises";
import os from "node:os";
import child_process from "node:child_process";
import { Buffer } from "node:buffer";

/**
 * Helper class for logging
 */
class Logger {
	/**
	 * @type {{ core?: import("github-script").AsyncFunctionArguments["core"] }}
	 */
	static #ACTIONS_CORE = { core: undefined };

	/**
	 * Initialize the logger
	 * @param {import("github-script").AsyncFunctionArguments["core"]} core
	 */
	static init(core) {
		Logger.#ACTIONS_CORE.core = core;
	}

	/**
	 * Emit a message to the logger
	 *
	 * @param {string} message
	 */
	static log(message) {
		console.log(message);
	}

	/**
	 * Emit a debug message to the logger
	 *
	 * @param {string} message
	 */
	static debug(message) {
		Logger.#ACTIONS_CORE.core?.debug(message);
	}

	/**
	 * Emit a warning message to the logger
	 *
	 * @param {string | Error} message
	 * @param {Parameters<import("github-script").AsyncFunctionArguments["core"]["warning"]>[1]} properties
	 */
	static warn(message, properties = undefined) {
		Logger.#ACTIONS_CORE.core?.warning(message, properties);
	}

	/**
	 * Emit a non-fatal error message to the logger and continue execution.
	 *
	 * @param {string | Error} message
	 * @param {Parameters<import("github-script").AsyncFunctionArguments["core"]["error"]>[1]} properties
	 */
	static error(message, properties = undefined) {
		Logger.#ACTIONS_CORE.core?.error(message, properties);
	}
}

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
		Logger.debug(`Getting last 10 checkruns for PR #${pullRequestNumber}`);
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
	const lastSuccessfulTofuPlanWorkflowRun = checkruns
		.filter(
			({ name, conclusion }) =>
				conclusion === "SUCCESS" && name === "Validate & Plan OpenTofu Changes",
		)
		.reduce((a, b) => {
			let aTimestamp = Date.parse(a.startedAt);
			let bTimestamp = Date.parse(b.startedAt);
			return aTimestamp > bTimestamp ? a : b;
		});

	Logger.debug(
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
		Logger.debug(`Found ${artifacts.length} artifacts`);
	}

	const tofuPlanArtifact = artifacts.find(({ name }) => name === "tofu-plan");
	if (tofuPlanArtifact === undefined) {
		throw new Error(`No artifact named "tofu-plan"`);
	} else {
		Logger.debug(`Found artifact named "tofu-plan".`);
	}

	const { url: artifactUrl } = await github.rest.actions.downloadArtifact({
		artifact_id: tofuPlanArtifact.id,
		archive_format: "zip",
		...context.repo,
	});

	Logger.log(`Downloading tofu-plan.zip from ${artifactUrl}`);

	const artifactResponse = await fetch(artifactUrl, {
		headers: { Authorization: `Bearer ${process.env.GITHUB_TOKEN}` },
		redirect: "follow",
	});

	Logger.debug(`Response:\n${JSON.stringify(artifactResponse, null, 2)}`);

	const zippedArtifactData = Buffer.from(await artifactResponse.arrayBuffer());
	return zippedArtifactData;
};

/**
 * Given an in-memory ZIP archive of a tofu plan, extract the plan file and return the path to it.
 *
 * @param {Buffer} zippedTofuPlanData
 */
const extractTofuPlanFromArchive = async (zippedTofuPlanData) => {
	const tmpdir = await fs.mkdtemp(path.join(os.tmpdir(), "tofu-plan-"));
	const zipFilePath = path.join(tmpdir, "tofu-plan.zip");
	const unzippedDirPath = path.join(tmpdir, "tofu-plan-unzipped");
	await fs.mkdir(unzippedDirPath, { recursive: true });

	Logger.debug(`Writing ZIP archive to ${zipFilePath}`);
	await fs.writeFile(zipFilePath, zippedTofuPlanData);

	Logger.debug(`Extracting ZIP archive to ${unzippedDirPath}`);

	// `unzip` is included in the ubuntu runners
	await new Promise((resolve, reject) =>
		child_process.exec(
			`unzip ${zipFilePath} -d ${unzippedDirPath}`,
			(error, stdout, stderr) => {
				if (stderr.length !== 0) {
					Logger.warn(stderr);
				}

				if (stdout.length !== 0) {
					Logger.log(stdout);
				}

				if (error !== null) {
					reject(error);
				} else {
					resolve(undefined);
				}
			},
		),
	);

	Logger.log(`Successfully extracted ZIP archive to ${unzippedDirPath}`);
	const files = await fs.readdir(unzippedDirPath);
	if (files.length !== 1) {
		throw Error(
			`Expected to find exactly one file in ${unzippedDirPath}, but found ${files.length}`,
		);
	}

	return path.join(unzippedDirPath, files[0]);
};

/**
 * Download the last successful tofu plan associated with this pull request
 *
 * @param {import("github-script").AsyncFunctionArguments} ctx
 */
export const downloadTofuPlan = async ({ github, context, core, io }) => {
	Logger.init(core);

	const lastTenCheckruns = await getLastTenCheckruns({ github, context });
	const runId = getLastSuccessfulTofuPlanWorkflowRunId(lastTenCheckruns);
	const zippedTofuPlanData = await downloadWorkflowArtifact({
		github,
		context,
		runId,
	});
	const tofuPlanPath = await extractTofuPlanFromArchive(zippedTofuPlanData);

	Logger.log(`Tofu plan is available at ${tofuPlanPath}`);
	return tofuPlanPath;
};
