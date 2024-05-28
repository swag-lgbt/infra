import fs from "node:fs";
import path from "node:path";
import url from "node:url";

import {
	config,
	default as tseslint,
	parser as typescriptParser,
} from "typescript-eslint";
import eslint from "@eslint/js";
import eslintConfigPrettier from "eslint-config-prettier";
import { findWorkspacePackagesNoCheck } from "@pnpm/workspace.find-packages";
import gitignore from "eslint-config-flat-gitignore";

/* eslint-disable no-underscore-dangle */
const __filename = url.fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
/* eslint-enable no-underscore-dangle */

const jsProjects = await findWorkspacePackagesNoCheck(__dirname);
const tsConfigJsonPaths = jsProjects
	.map(({ dir }) => path.join(dir, "tsconfig.json"))
	.filter((tsconfigPath) => fs.existsSync(tsconfigPath));

tsConfigJsonPaths.push(path.resolve(__dirname, "tsconfig.eslint.json"));

export default config(
	gitignore({ root: true }),
	eslint.configs.all,
	...tseslint.configs.strictTypeChecked,
	...tseslint.configs.stylisticTypeChecked,
	{
		languageOptions: {
			ecmaVersion: "latest",
			parser: typescriptParser,
			parserOptions: {
				ecmaFeatures: {
					jsx: true,
				},
				project: tsConfigJsonPaths,
				sourceType: "module",
				tsconfigRootDir: __dirname,
			},
		},
		rules: {
			"@typescript-eslint/restrict-template-expressions": [
				"error",
				{ allowNumber: true },
			],
			"max-lines": [
				"warn",
				{ max: 200, skipBlankLines: true, skipComments: true },
			],
			"max-lines-per-function": [
				"warn",
				{ max: 40, skipBlankLines: true, skipComments: true },
			],
			"no-global-assign": "error",
			"no-magic-numbers": ["warn", { ignore: [0, 1] }],
			"no-shadow-restricted-names": "error",
			"no-ternary": "off",
			"no-undefined": "off",
			"no-useless-assignment": "off",
			"no-void": ["error", { allowAsStatement: true }],
			"one-var": ["error", "never"],
			"sort-imports": "off",
		},
	},
	eslintConfigPrettier,
);
