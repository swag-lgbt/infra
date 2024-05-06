/**
 * Get the latest
 * @param {import("github-script").AsyncFunctionArguments} ctx
 */
export const getLatestWorkflowRunId = async ({ github, context, core }) => {
  const {
    data: {
      workflow_runs: [latestWorkflowRun],
    },
  } = await github.rest.actions.listWorkflowRuns({
    owner: context.repo.owner,
    repo: context.repo.repo,
    workflow_id: "tofu.yml",
    per_page: 1,
    branch: process.env.GITHUB_HEAD_REF,
  });

  return latestWorkflowRun.id.toString(10)
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
