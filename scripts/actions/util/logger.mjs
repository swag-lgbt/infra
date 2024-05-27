import console from "node:console";

/**
 * @type {{ core?: import("github-script").AsyncFunctionArguments["core"] }}
 */
const ACTIONS_CORE = { core: undefined };

/**
 * Initialize the logger
 * @param {import("github-script").AsyncFunctionArguments["core"]} core
 */
export const init = (core) => {
	ACTIONS_CORE.core = core;
};

/**
 * Emit a message to the logger
 *
 * @param {string} message
 */
export const log = (message) => {
	console.log(message);
};

/**
 * Emit a debug message to the logger
 *
 * @param {string} message
 */
export const debug = (message) => {
	ACTIONS_CORE.core?.debug(message);
};

/**
 * Emit a warning message to the logger
 *
 * @param {string | Error} message
 * @param {Parameters<import("github-script").AsyncFunctionArguments["core"]["warning"]>[1]} properties
 */
export const warn = (message, properties = undefined) => {
	ACTIONS_CORE.core?.warning(message, properties);
};

/**
 * Emit a non-fatal error message to the logger and continue execution.
 *
 * @param {string | Error} message
 * @param {Parameters<import("github-script").AsyncFunctionArguments["core"]["error"]>[1]} properties
 */
export const error = (message, properties = undefined) => {
	ACTIONS_CORE.core?.error(message, properties);
};
