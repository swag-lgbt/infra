const getStepInfo = () => {
  return {
    fmt: { outcome: process.env.FMT_OUTCOME },
    init: { outcome: process.env.INIT_OUTCOME },
    validate: {
      outcome: process.env.VALIDATE_OUTCOME,
      outputs: { stdout: process.env.VALIDATE_STDOUT },
    },
    plan: {
      outcome: process.env.PLAN_OUTCOME,
      outputs: { stdout: process.env.PLAN_STDOUT },
    },
  };
};

/**
 * Create or edit bot comments on Tofu PR's
 *
 * @param {import('@types/github-script').AsyncFunctionArguments} AsyncFunctionArguments
 */
export const makePrComment = async ({
  github,
  context,
  core,
  glob,
  io,
  exec,
  require,
}) => {
  const steps = getStepInfo();

  // 1. Retrieve existing bot comments for the PR
  const { data: comments } = await github.rest.issues.listComments({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.issue.number,
  });

  const botComment = comments.find((comment) => {
    return (
      comment.user.type === "Bot" &&
      comment.body.includes("OpenTofu Format and Style")
    );
  });

  // 2. Prepare format of the comment
  const output = `#### OpenTofu Format and Style 🖌\`${steps.fmt.outcome}\`
  #### OpenTofu Initialization ⚙️\`${steps.init.outcome}\`
  #### OpenTofu Validation 🤖\`${steps.validate.outcome}\`
  <details><summary>Validation Output</summary>

  \`\`\`\n
  ${steps.validate.outputs.stdout}
  \`\`\`

  </details>

  #### OpenTofu Plan 📖\`${steps.plan.outcome}\`

  <details><summary>Show Plan</summary>

  \`\`\`\n
  ${process.env.PLAN}
  \`\`\`

  </details>`;

  // 3. If we have a comment, update it, otherwise create a new one
  if (botComment) {
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
