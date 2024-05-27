/**
 * Retrieve an existing bot comment from a PR
 *
 * @param {Pick<import("github-script").AsyncFunctionArguments, "github" | "context">} ctx
 */
const getExistingBotComment = async ({ context, github }) => {
	const { data: comments } = await github.rest.issues.listComments({
		// eslint-disable-next-line camelcase
		issue_number: context.issue.number,
		owner: context.repo.owner,
		repo: context.repo.repo,
	});

	return comments.find(
		(comment) =>
			comment.user?.type === "Bot" &&
			comment.body?.includes("OpenTofu Validation 🤖"),
	);
};

/**
 * Create some markdown to comment based on the outcome of previous CI steps
 *
 * @param {{
 *  fmt: { outcome: string; };
 *  init: { outcome: string; };
 *  lint: { outcome: string; };
 *  validate: { outcome: string; stdout: string; };
 *  plan: { outcome: string; stdout: string; }
 * 	}} steps
 */
const createCommentBody = (
	steps,
) => `#### OpenTofu Validation 🤖\`${steps.validate.outcome}\`

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

/**
 * Create or edit bot comments on Tofu PR's
 *
 * @param {import("github-script").AsyncFunctionArguments & {
 * 	steps: {
 *  	fmt: { outcome: string; };
 *  	init: { outcome: string; };
 *  	lint: { outcome: string; };
 *  	validate: { outcome: string; stdout: string; };
 *  	plan: { outcome: string; stdout: string; }
 * 	}
 * }} ctx
 */
export const makePrComment = async ({ steps, github, context }) => {
	// 1. Retrieve existing bot comment for the PR
	const botComment = await getExistingBotComment({ context, github });

	// 2. Prepare format of the comment
	const commentBody = createCommentBody(steps);

	// 3. If we have a comment, update it, otherwise create a new one
	if (typeof botComment === "undefined") {
		await github.rest.issues.createComment({
			body: commentBody,
			// eslint-disable-next-line camelcase
			issue_number: context.issue.number,
			owner: context.repo.owner,
			repo: context.repo.repo,
		});
	} else {
		await github.rest.issues.updateComment({
			body: commentBody,
			// eslint-disable-next-line camelcase
			comment_id: botComment.id,
			owner: context.repo.owner,
			repo: context.repo.repo,
		});
	}
};
