import type { DocumentHead } from "@builder.io/qwik-city";
import { component$ } from "@builder.io/qwik";

export default component$(() => (
	<>
		<div class="container container-flex">
			<div q:slot="title" class="icon icon-cli">
				CLI Commands
			</div>
			<>
				<p>
					<code>npm run dev</code>
					<br />
					Starts the development server and watches for changes
				</p>
				<p>
					<code>npm run preview</code>
					<br />
					Creates production build and starts a server to preview it
				</p>
				<p>
					<code>npm run build</code>
					<br />
					Creates production build
				</p>
				<p>
					<code>npm run qwik add</code>
					<br />
					Runs the qwik CLI to add integrations
				</p>
			</>
		</div>
	</>
));

export const head: DocumentHead = {
	meta: [
		{
			content:
				"Single Sign-On and account management for the swagLGBT universe",
			name: "description",
		},
	],
	title: "passportLGBT",
};
