<script lang="ts" module>
	import { MathMorph } from '@canon/lib/math/draw.ts';

	const morphers = new WeakMap<SVGGElement, MathMorph>();
</script>

<script lang="ts">
	import type { Attachment } from 'svelte/attachments';
	import type { HTMLAttributes } from 'svelte/elements';
	import { drawBox } from '@canon/lib/math/draw.ts';
	import { canvasMetrics } from '@canon/lib/math/measure.ts';
	import { keyed } from '@canon/lib/math/morph.ts';
	import { N, parse, present } from '@canon/lib/math/node.ts';
	import {
		Typesetter,
		type Box,
		type Ink,
	} from '@canon/lib/math/typeset.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-math-view.css';

	interface Props extends HTMLAttributes<Element> {
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
	}

	let {
		text,
		box: givenBox,
		size = 22,
		ink = 'result',
		presents,
		faint,
		mono,
		morphs,
		label: givenLabel,
		class: className,
		...rest
	}: Props = $props();

	const box = $derived.by((): Box => {
		if (givenBox) return givenBox;
		const setter = new Typesetter(canvasMetrics, size, ink);
		const source = text ?? '';
		const node = parse(source);
		return setter.layout(
			node
				? presents
					? present(node)
					: node
				: N.word(source),
		);
	});
	const label = $derived(givenLabel ?? text);
	const classes = $derived([
		'canon-math-view',
		faint && 'canon-math-view--faint',
		mono && 'canon-math-view--mono',
	]);

	const draw =
		(box: Box): Attachment<SVGSVGElement> =>
		(svg) =>
			drawBox(svg, box);

	const morph =
		(box: Box): Attachment<SVGGElement> =>
		(group) => {
			const host =
				group.closest<HTMLElement>('.canon-math-view')!;
			const morpher =
				morphers.get(group) ?? new MathMorph(group);
			morphers.set(group, morpher);
			const place = (animated: boolean) => {
				const scale = Math.min(
					1,
					host.clientWidth /
						Math.max(box.width, 1),
					host.clientHeight /
						Math.max(box.height, 1),
				);
				const left =
					(host.clientWidth - box.width * scale) /
					2;
				const top =
					(host.clientHeight -
						box.height * scale) /
						2 +
					box.ascent * scale;
				morpher.show(
					keyed(box.atoms, 'view', (atom) => ({
						atom: {
							...atom,
							weight:
								atom.weight *
								scale,
						},
						frame: {
							x:
								left +
								atom.frame.x *
									scale,
							y:
								top +
								atom.frame.y *
									scale,
							width:
								atom.frame
									.width *
								scale,
							height:
								atom.frame
									.height *
								scale,
						},
						alpha: 1,
					})),
					animated,
				);
			};
			place(group.childElementCount > 0);
			let width = host.clientWidth;
			const resize = new ResizeObserver(() => {
				if (host.clientWidth === width) return;
				width = host.clientWidth;
				place(false);
			});
			resize.observe(host);
			return () => resize.disconnect();
		};
</script>

<!--
  @component
  Typeset atoms drawn at their own size, scaled down to fit a narrower
  frame and centred (CanonMathView). With `morphs`, a change animates
  through CanonMathMorph.
-->
{#if morphs}
	<div
		class={[...classes, 'canon-math-view--morph', className]}
		style="min-block-size: {Math.ceil(box.height)}px"
		{...rest}
	>
		<svg role="img" aria-label={label}
			><g {@attach morph(box)}></g></svg
		>
	</div>
{:else}
	<svg
		class={[...classes, className]}
		role="img"
		aria-label={label}
		{@attach draw(box)}
		{...rest}
	></svg>
{/if}
