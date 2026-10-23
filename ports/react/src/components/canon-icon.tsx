import type { SVGProps } from 'react';

export interface CanonIconProps {
	/** An SVG string, as lucide-static exports it or a `?raw` import. */
	svg: string;
}

const parsed = new Map<string, SVGProps<SVGSVGElement>>();

function parse(svg: string): SVGProps<SVGSVGElement> {
	let props = parsed.get(svg);
	if (props) return props;
	const match = /<svg([^>]*)>([\s\S]*)<\/svg>/.exec(svg);
	const attributes: Record<string, string> = {};
	for (const [, name = '', value = ''] of (match?.[1] ?? '').matchAll(
		/([\w:-]+)="([^"]*)"/g,
	)) {
		// lucide's fixed 24 px size would override the CSS box the call site gives the svg
		if (name === 'width' || name === 'height') continue;
		const key =
			name === 'class'
				? 'className'
				: name.startsWith('aria-') ||
					  name.startsWith('data-')
					? name
					: name.replace(
							/-(\w)/g,
							(_, c: string) =>
								c.toUpperCase(),
						);
		attributes[key] = value;
	}
	props = {
		...attributes,
		dangerouslySetInnerHTML: { __html: match?.[2] ?? '' },
	};
	parsed.set(svg, props);
	return props;
}

/** Renders an SVG string as its own `<svg>` element, sized by CSS. */
export default function CanonIcon({ svg }: CanonIconProps) {
	return <svg {...parse(svg)} />;
}
