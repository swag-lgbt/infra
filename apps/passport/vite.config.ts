import {
	type QwikCityVitePluginOptions,
	qwikCity,
} from "@builder.io/qwik-city/vite";
import { type UserConfig, defineConfig } from "vite";
import { execa } from "execa";
import { qwikVite } from "@builder.io/qwik/optimizer";
import tsconfigPaths from "vite-tsconfig-paths";

import pkg from "./package.json";

if ("dependencies" in pkg) {
	throw new Error(
		"Please move dependencies to devDependencies, or implement dependency de-duplication here.",
	);
}

const getNestedChildProperty = (
	parent: unknown,
	...keys: (string | number | symbol)[]
): unknown => {
	if (keys.length === 0) {
		return parent;
	}

	const [firstKey, ...restKeys] = keys;

	if (Array.isArray(parent) && typeof firstKey === "number") {
		const nextChild = parent[firstKey] as unknown;
		return getNestedChildProperty(nextChild, ...restKeys);
	} else if (
		typeof parent === "object" &&
		parent !== null &&
		firstKey in parent
	) {
		const nextChild = (parent as Record<typeof firstKey, unknown>)[firstKey];
		return getNestedChildProperty(nextChild, ...restKeys);
	}

	throw new Error(
		`Cannot index into ${JSON.stringify(parent)} with key ${firstKey.toString()}`,
	);
};

interface CloudflarePagesDeploymentConfig {
	environment_variables: Record<string, string>;
	secrets: Record<string, string>;
}

const isCloudflarePagesDeploymentConfig = (
	deploymentConfig: unknown,
): deploymentConfig is CloudflarePagesDeploymentConfig =>
	typeof deploymentConfig === "object" &&
	deploymentConfig !== null &&
	"environment_variables" in deploymentConfig &&
	typeof deploymentConfig.environment_variables === "object" &&
	deploymentConfig.environment_variables !== null &&
	"secrets" in deploymentConfig &&
	typeof deploymentConfig.secrets === "object" &&
	deploymentConfig.secrets !== null;

const parseTofuOutputsIntoCloudflareBindings = (outputs: unknown): Env => {
	if (typeof outputs !== "object") {
		throw new Error(`Expected an object, received ${typeof outputs} instead.`);
	}

	if (outputs === null) {
		throw new Error(`Unexpected null attempting to parse Tofu outputs`);
	}

	const nestedKeys = [
		"apps",
		"value",
		"passport",
		"preview_deployment_config",
		0,
	];
	const previewDeploymentConfig = getNestedChildProperty(
		outputs,
		...nestedKeys,
	);
	if (!isCloudflarePagesDeploymentConfig(previewDeploymentConfig)) {
		throw new Error(
			`Expected output ${nestedKeys.join(".")} to be a Cloudflare Pages deployment config, but it wasn't.`,
		);
	}

	return {
		NODE_VERSION: previewDeploymentConfig.environment_variables.NODE_VERSION,
		OAUTH_REDIRECT_API: previewDeploymentConfig.secrets.OAUTH_REDIRECT_API,
		PNPM_VERSION: previewDeploymentConfig.environment_variables.PNPM_VERSION,
		STYTCH_PUBLIC_TOKEN: previewDeploymentConfig.secrets.STYTCH_PUBLIC_TOKEN,
	};
};

const getPreviewBindings = async (): Promise<
	QwikCityVitePluginOptions["platform"]
> => {
	// In dev mode, we need to inject variables from terraform into our app.
	// In production, these are set through terraform's configuration of cloudflare pages.
	const { stdout, exitCode, stderr } = await execa`just tofu output -json`;
	if (exitCode && exitCode !== 0) {
		throw new Error(
			`Error attempting to get tofu output to set dev vars:\n\n${stderr}`,
		);
	}

	const tofuOutputs = JSON.parse(stdout) as unknown;
	const env = parseTofuOutputsIntoCloudflareBindings(tofuOutputs);
	return { env };
};

/**
 * Note that Vite normally starts from `index.html` but the qwikCity plugin makes start at `src/entry.ssr.tsx` instead.
 */
export default defineConfig(async ({ command }): Promise<UserConfig> => {
	// Set up mock cloudflare bindings in dev mode, leave it be in prod
	const platform = command === "serve" ? await getPreviewBindings() : undefined;

	return {
		// This tells Vite which dependencies to pre-build in dev mode.
		optimizeDeps: {
			// Put problematic deps that break bundling here, mostly those with binaries.
			// For example ['better-sqlite3'] if you use that in server functions.
			exclude: [],
		},
		plugins: [qwikCity({ platform }), qwikVite(), tsconfigPaths()],
		preview: {
			headers: {
				// Do cache the server response in preview (non-adapter production build)
				"Cache-Control": "public, max-age=600",
			},
		},
		server: {
			headers: {
				// Don't cache the server response in dev mode
				"Cache-Control": "public, max-age=0",
			},
		},
	};
});
