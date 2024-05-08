/**
 *
 * @param {import("github-script").AsyncFunctionArguments["core"]} core \@actions/core lib
 * @returns {(message: string) => Error} error reporter
 */
const errorReporterFactory = (core) => (message) => {
	const error = new Error(message);
	core.setFailed(error);
	return error;
};

/**
 * Get the latest
 * @param {import("github-script").AsyncFunctionArguments} ctx
 */
export const getLastSuccessfulTofuPlanRunId = async ({
	github,
	context,
	core,
}) => {
	const error = errorReporterFactory(core);
	const pullRequestNumber = context.payload.pull_request?.number;

	if (typeof pullRequestNumber !== "number") {
		throw error("Failed to determine PR number");
	}

	/**
	 * @type {{
	 *  lastTenWorkflowRuns: {
	 *    repository: {
	 *      pullRequest: {
	 *        statusCheckRollup: {
	 *          contexts: {
	 *            nodes: {
	 *              name: string;
	 *              conclusion: "FAILURE" | "SUCCESS" | "SKIPPED";
	 *              startedAt: string;
	 *              checkSuite: {
	 *                workflowRun: {
	 *                  runNumber: number;
	 *                }
	 *              }
	 *            }[]
	 *          }
	 *        }
	 *      }
	 *    }
	 *  }
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
                  runNumber
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

	const lastTenCheckruns =
		response.lastTenWorkflowRuns.repository.pullRequest.statusCheckRollup
			.contexts.nodes;

	const lastSuccessfulTofuPlanWorkflow = lastTenCheckruns
		.filter(
			({ name, conclusion }) =>
				conclusion === "SUCCESS" && name === "Plan OpenTofu Changes",
		)
		.reduce((a, b) => {
			let aTimestamp = Date.parse(a.startedAt);
			let bTimestamp = Date.parse(b.startedAt);
			return aTimestamp > bTimestamp ? a : b;
		});

	const {
		checkSuite: {
			workflowRun: { runNumber: run_id },
		},
	} = lastSuccessfulTofuPlanWorkflow;

	return run_id.toString(10);
};

/**
 * Create or edit bot comments on Tofu PR's
 *
 * @param {{
 *  fmt: { outcome: string; };
 *  init: { outcome: string; };
 *  lint: { outcome: string; };
 *  validate: { outcome: string; stdout: string; };
 *  plan: { outcome: string; stdout: string; }
 * }} steps
 * @param {import("github-script").AsyncFunctionArguments} ctx
 */
export const makePrComment = async (steps, { github, context }) => {
	// 1. Retrieve existing bot comments for the PR
	const { data: comments } = await github.rest.issues.listComments({
		owner: context.repo.owner,
		repo: context.repo.repo,
		issue_number: context.issue.number,
	});

	const botComment = comments.find((comment) => {
		return (
			comment.user?.type === "Bot" &&
			comment.body?.includes("OpenTofu Format and Style")
		);
	});

	// 2. Prepare format of the comment
	const output = `#### OpenTofu Format and Style 🖌\`${steps.fmt.outcome}\`
  #### OpenTofu Initialization ⚙️\`${steps.init.outcome}\`
  #### TFLint ☑️\`${steps.lint.outcome}\`
  #### OpenTofu Validation 🤖\`${steps.validate.outcome}\`
  <details><summary>Validation Output</summary>

  \`\`\`\n
  ${steps.validate.stdout}
  \`\`\`

  </details>

  #### OpenTofu Plan 📖\`${steps.plan.outcome}\`

  <details><summary>Show Plan</summary>

  \`\`\`\n
  ${steps.plan.stdout}
  \`\`\`

  </details>`;

	// 3. If we have a comment, update it, otherwise create a new one
	if (botComment !== undefined) {
		github.rest.issues.updateComment({
			owner: context.repo.owner,
			repo: context.repo.repo,
			comment_id: botComment.id,
			body: output,
		});
	} else {
		github.rest.issues.createComment({
			issue_number: context.issue.number,
			owner: context.repo.owner,
			repo: context.repo.repo,
			body: output,
		});
	}
};
