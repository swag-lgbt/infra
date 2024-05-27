/**
 * This is the base config for vite.
 * When building, the adapter config is used which loads this file and extends it.
 */
import { type UserConfig, defineConfig } from "vite";
import { qwikCity } from "@builder.io/qwik-city/vite";
import { qwikVite } from "@builder.io/qwik/optimizer";
import tsconfigPaths from "vite-tsconfig-paths";

import pkg from "./package.json";

if ("dependencies" in pkg) {
	throw new Error(
		"Please move dependencies to devDependencies, or implement dependency de-duplication here.",
	);
}

/**
 * Note that Vite normally starts from `index.html` but the qwikCity plugin makes start at `src/entry.ssr.tsx` instead.
 */
export default defineConfig(
	(): UserConfig => ({
		// This tells Vite which dependencies to pre-build in dev mode.
		optimizeDeps: {
			// Put problematic deps that break bundling here, mostly those with binaries.
			// For example ['better-sqlite3'] if you use that in server functions.
			exclude: [],
		},
		plugins: [qwikCity(), qwikVite(), tsconfigPaths()],
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
	}),
);
