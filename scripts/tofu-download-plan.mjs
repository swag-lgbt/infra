import path from "node:path";
import process from "node:process";
import fs from "node:fs/promises";
import os from "node:os";
import { Buffer } from "node:buffer";

import Zip from "adm-zip";

/**
 * Retrieve the last 10 checkruns (i.e. workflows) that ran on this pull request.
 *
 * @param {Pick<import("github-script").AsyncFunctionArguments, "github" | "context">} ctx
 */
const getLastTenCheckruns = async ({ github, context }) => {
	const pullRequestNumber = context.payload.pull_request?.number;

	if (typeof pullRequestNumber !== "number") {
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
	return checkruns
		.filter(
			({ name, conclusion }) =>
				conclusion === "SUCCESS" && name === "Validate & Plan OpenTofu Changes",
		)
		.reduce((a, b) => {
			let aTimestamp = Date.parse(a.startedAt);
			let bTimestamp = Date.parse(b.startedAt);
			return aTimestamp > bTimestamp ? a : b;
		}).checkSuite.workflowRun.databaseId;
};

/**
 * Download an artifact named `tofu-plan` from a given workflow run
 *
 * @param {Pick<import("github-script").AsyncFunctionArguments, "github" | "context"> & { runId: number }} ctx
 */
const downloadWorkflowArtifact = async ({ github, context, runId }) => {
	const {
		data: { artifacts },
	} = await github.rest.actions.listWorkflowRunArtifacts({
		name: "tofu-plan",
		run_id: runId,
		...context.repo,
	});

	if (artifacts.length === 0) {
		throw new Error(`No artifacts found for workflow run ${runId}`);
	}

	const tofuPlanArtifact = artifacts.find(({ name }) => name === "tofu-plan");
	if (tofuPlanArtifact === undefined) {
		throw new Error(`No artifact named "tofu-plan"`);
	}

	const { url: artifactUrl } = await github.rest.actions.downloadArtifact({
		artifact_id: tofuPlanArtifact.id,
		archive_format: "zip",
		...context.repo,
	});

	// response will be 302, so by following we can just download in one shot.
	const artifactResponse = await fetch(artifactUrl, {
		headers: { Authorization: `Bearer ${process.env.GITHUB_TOKEN}` },
		redirect: "follow",
	});

	const zippedArtifactData = Buffer.from(await artifactResponse.arrayBuffer());
	return zippedArtifactData;
};

/**
 * Extract a file from a ZIP archive with one entry in it.
 *
 * @param {Buffer} zippedTofuPlanData
 */
const extractTofuPlanFromArchive = async (zippedTofuPlanData) => {
	const tmpdir = await fs.mkdtemp(path.join(os.tmpdir(), "tofu-plan-"));
	const zippedFilePath = path.join(tmpdir, "tofu-plan.zip");

	await fs.writeFile(zippedFilePath, zippedTofuPlanData);

	const zipper = new Zip(zippedFilePath);
	if (zipper.getEntryCount() !== 1) {
		throw new Error("Expected exactly one entry, which is the plan to apply");
	}

	const planEntry = zipper.getEntries()[0];
	return planEntry.getData();
};

/**
 * Download the last successful tofu plan associated with this pull request
 *
 * @param {import("github-script").AsyncFunctionArguments} ctx
 */
export const downloadTofuPlan = async ({ github, context }) => {
	const lastTenCheckruns = await getLastTenCheckruns({ github, context });
	const runId = getLastSuccessfulTofuPlanWorkflowRunId(lastTenCheckruns);
	const zippedTofuPlanData = await downloadWorkflowArtifact({
		github,
		context,
		runId,
	});
	const tofuPlan = await extractTofuPlanFromArchive(zippedTofuPlanData);
	const tofuPlanPath = path.resolve(__dirname, "tofu-plan");

	await fs.writeFile(tofuPlanPath, tofuPlan);

	return tofuPlanPath;
};
