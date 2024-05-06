import { FlatCompat } from "@eslint/eslintrc";
import { config, default as tseslint } from 'typescript-eslint';
import eslint from '@eslint/js';

import path from 'node:path';
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const compat = new FlatCompat({
    baseDirectory: __dirname
});

export default config(
  eslint.configs.all,
  ...tseslint.configs.strict,
  ...tseslint.configs.stylistic,
  ...compat.extends("plugin:qwik/recommended")
)