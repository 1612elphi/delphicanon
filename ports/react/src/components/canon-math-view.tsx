import { useCallback, useMemo, type HTMLAttributes, type Ref } from 'react';
import { drawBox, MathMorph } from '@canon/lib/math/draw.ts';
import { canvasMetrics } from '@canon/lib/math/measure.ts';
import { keyed } from '@canon/lib/math/morph.ts';
import { N, parse, present } from '@canon/lib/math/node.ts';
import { Typesetter, type Box, type Ink } from '@canon/lib/math/typeset.ts';
import { cx } from '../lib/class-names.ts';
import { useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-view.css';

export interface CanonMathViewProps extends Omit<
	HTMLAttributes<Element>,
	'children'
> {
	/** nerdamer syntax; text that does not parse is set upright as it is. */
	text?: string;
	/** A box set elsewhere; wins over `text`. */
	box?: Box;
	/** Font size in px; default 22. */
	size?: number;
	ink?: Ink;
	/** Sets a result as written by hand: falling powers, fractions, roots. */
	presents?: boolean;
	/** Placeholder opacity. */
	faint?: boolean;
	/** Every atom in the current colour, as a key label. */
	mono?: boolean;
	/** A change slides the glyphs that stay, grows new ones and fades removed ones. */
	morphs?: boolean;
	/** Accessible name; default the text. */
	label?: string;
	ref?: Ref<Element>;
}

const morphers = new WeakMap<SVGGElement, MathMorph>();

function morph(group: SVGGElement, box: Box) {
	const host = group.closest<HTMLElement>('.canon-math-view')!;
	const morpher = morphers.get(group) ?? new MathMorph(group);
	morphers.set(group, morpher);
	const place = (animated: boolean) => {
		const scale = Math.min(
			1,
			host.clientWidth / Math.max(box.width, 1),
			host.clientHeight / Math.max(box.height, 1),
		);
		const left = (host.clientWidth - box.width * scale) / 2;
		const top =
			(host.clientHeight - box.height * scale) / 2 +
			box.ascent * scale;
		morpher.show(
			keyed(box.atoms, 'view', (atom) => ({
				atom: { ...atom, weight: atom.weight * scale },
				frame: {
					x: left + atom.frame.x * scale,
					y: top + atom.frame.y * scale,
					width: atom.frame.width * scale,
					height: atom.frame.height * scale,
				},
				alpha: 1,
			})),
			animated,
		);
	};
	const drawn = group.childElementCount > 0;
	place(drawn);
	let width = host.clientWidth;
	const resize = new ResizeObserver(() => {
		if (host.clientWidth === width) return;
		width = host.clientWidth;
		place(false);
	});
	resize.observe(host);
	return () => resize.disconnect();
}

/**
 * Typeset atoms drawn at their own size, scaled down to fit a narrower
 * frame and centred (CanonMathView). With `morphs`, a change animates
 * through CanonMathMorph.
 */
export default function CanonMathView({
	text,
	box: given,
	size,
	ink,
	presents,
	faint,
	mono,
	morphs,
	label,
	className,
	style,
	ref,
	...rest
}: CanonMathViewProps) {
	const box = useMemo(() => {
		if (given) return given;
		const setter = new Typesetter(
			canvasMetrics,
			size ?? 22,
			ink ?? 'result',
		);
		const node = parse(text ?? '');
		return setter.layout(
			node
				? presents
					? present(node)
					: node
				: N.word(text ?? ''),
		);
	}, [given, text, size, ink, presents]);

	const draw = useCallback(
		(svg: SVGSVGElement | null) => {
			if (svg) drawBox(svg, box);
		},
		[box],
	);
	const morphing = useCallback(
		(group: SVGGElement | null) =>
			group ? morph(group, box) : undefined,
		[box],
	);
	const refs = useRefs<Element>(morphs ? undefined : draw, ref);

	const classes = cx(
		'canon-math-view',
		morphs && 'canon-math-view--morph',
		faint && 'canon-math-view--faint',
		mono && 'canon-math-view--mono',
		className,
	);

	if (morphs)
		return (
			<div
				className={classes}
				style={{
					minBlockSize: `${Math.ceil(box.height)}px`,
					...style,
				}}
				ref={refs}
				{...rest}
			>
				<svg role="img" aria-label={label ?? text}>
					<g ref={morphing} />
				</svg>
			</div>
		);
	return (
		<svg
			className={classes}
			role="img"
			aria-label={label ?? text}
			style={style}
			ref={refs}
			{...rest}
		/>
	);
}
