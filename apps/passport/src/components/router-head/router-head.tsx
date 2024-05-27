import { useDocumentHead, useLocation } from "@builder.io/qwik-city";
import { component$ } from "@builder.io/qwik";

/**
 * The RouterHead component is placed inside of the document `<head>` element.
 */
export const RouterHead = component$(() => {
	const head = useDocumentHead();
	const loc = useLocation();

	return (
		<>
			<title>{head.title}</title>

			<link rel="canonical" href={loc.url.href} />
			<meta name="viewport" content="width=device-width, initial-scale=1.0" />
			<link rel="icon" type="image/svg+xml" href="/favicon.svg" />

			{head.meta.map((metaItem) => (
				<meta key={metaItem.key} {...metaItem} />
			))}

			{head.links.map((linkItem) => (
				<link key={linkItem.key} {...linkItem} />
			))}

			{head.styles.map((styleItem) => (
				<style
					key={styleItem.key}
					{...styleItem.props}
					{...(styleItem.props?.dangerouslySetInnerHTML
						? {}
						: { dangerouslySetInnerHTML: styleItem.style })}
				/>
			))}

			{head.scripts.map((scriptItem) => (
				<script
					key={scriptItem.key}
					{...scriptItem.props}
					{...(scriptItem.props?.dangerouslySetInnerHTML
						? {}
						: { dangerouslySetInnerHTML: scriptItem.script })}
				/>
			))}
		</>
	);
});
