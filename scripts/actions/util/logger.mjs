/**
 * Helper class for logging
 */
export class Logger {
	/**
	 * @type {{ core?: import("github-script").AsyncFunctionArguments["core"] }}
	 */
	static #ACTIONS_CORE = { core: undefined };

	/**
	 * Initialize the logger
	 * @param {import("github-script").AsyncFunctionArguments["core"]} core
	 */
	static init(core) {
		Logger.#ACTIONS_CORE.core = core;
	}

	/**
	 * Emit a message to the logger
	 *
	 * @param {string} message
	 */
	static log(message) {
		console.log(message);
	}

	/**
	 * Emit a debug message to the logger
	 *
	 * @param {string} message
	 */
	static debug(message) {
		Logger.#ACTIONS_CORE.core?.debug(message);
	}

	/**
	 * Emit a warning message to the logger
	 *
	 * @param {string | Error} message
	 * @param {Parameters<import("github-script").AsyncFunctionArguments["core"]["warning"]>[1]} properties
	 */
	static warn(message, properties = undefined) {
		Logger.#ACTIONS_CORE.core?.warning(message, properties);
	}

	/**
	 * Emit a non-fatal error message to the logger and continue execution.
	 *
	 * @param {string | Error} message
	 * @param {Parameters<import("github-script").AsyncFunctionArguments["core"]["error"]>[1]} properties
	 */
	static error(message, properties = undefined) {
		Logger.#ACTIONS_CORE.core?.error(message, properties);
	}
}
