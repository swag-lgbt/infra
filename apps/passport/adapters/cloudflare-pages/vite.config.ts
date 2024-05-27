import { cloudflarePagesAdapter } from "@builder.io/qwik-city/adapters/cloudflare-pages/vite";
import { extendConfig } from "@builder.io/qwik-city/vite";

import baseConfig from "../../vite.config";

export default extendConfig(baseConfig, () => ({
	build: {
		rollupOptions: {
			input: ["src/entry.cloudflare-pages.tsx", "@qwik-city-plan"],
		},
		ssr: true,
	},
	plugins: [cloudflarePagesAdapter()],
}));
