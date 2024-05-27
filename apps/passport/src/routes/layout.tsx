import { type RequestHandler, routeLoader$ } from "@builder.io/qwik-city";
import { Slot, component$, useStyles$ } from "@builder.io/qwik";

import styles from "./styles.css?inline";

const secondsPerMinute = 60;
const minutesPerHour = 60;
const hoursPerDay = 24;
const daysPerWeek = 7;

const oneWeek = secondsPerMinute * minutesPerHour * hoursPerDay * daysPerWeek;

export const onGet: RequestHandler = ({ cacheControl }) => {
	// Control caching for this request for best performance and to reduce hosting costs:
	// https://qwik.dev/docs/caching/
	cacheControl({
		// Max once every 5 seconds, revalidate on the server to get a fresh version of this page
		maxAge: 5,
		// Always serve a cached response by default, up to a week stale
		staleWhileRevalidate: oneWeek,
	});
};

export const useServerTimeLoader = routeLoader$(() => ({
	date: new Date().toISOString(),
}));

export default component$(() => {
	useStyles$(styles);
	return (
		<>
			<main>
				<Slot />
			</main>
		</>
	);
});
