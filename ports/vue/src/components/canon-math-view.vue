<script lang="ts">
import { MathMorph } from '@canon/lib/math/draw.ts';

const groupMorphs = new WeakMap<SVGGElement, MathMorph>();
</script>

<script setup lang="ts">
import { computed, useTemplateRef, watch } from 'vue';
import { drawBox } from '@canon/lib/math/draw.ts';
import { canvasMetrics } from '@canon/lib/math/measure.ts';
import { keyed } from '@canon/lib/math/morph.ts';
import { N, parse, present } from '@canon/lib/math/node.ts';
import { Typesetter, type Box, type Ink } from '@canon/lib/math/typeset.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-view.css';

defineOptions({ inheritAttrs: false });

const props = defineProps<{
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
}>();

const box = computed((): Box => {
	if (props.box) return props.box;
	const setter = new Typesetter(
		canvasMetrics,
		props.size ?? 22,
		props.ink ?? 'result',
	);
	const text = props.text ?? '';
	const node = parse(text);
	return setter.layout(
		node ? (props.presents ? present(node) : node) : N.word(text),
	);
});

const label = computed(() => props.label ?? props.text);
// a consumer's style replaces this, as it does after Ember's ...attributes
const morphStyle = computed(
	() => `min-block-size: ${Math.ceil(box.value.height)}px`,
);

const svg = useTemplateRef<SVGSVGElement>('svg');
const group = useTemplateRef<SVGGElement>('group');

watch(
	[svg, box],
	([svg, box]) => {
		if (svg) drawBox(svg, box);
	},
	{ flush: 'post' },
);

watch(
	[group, box],
	([group, box], _, onCleanup) => {
		if (!group) return;
		const host = group.closest<HTMLElement>('.canon-math-view')!;
		const morph = groupMorphs.get(group) ?? new MathMorph(group);
		groupMorphs.set(group, morph);
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
			morph.show(
				keyed(box.atoms, 'view', (atom) => ({
					atom: {
						...atom,
						weight: atom.weight * scale,
					},
					frame: {
						x: left + atom.frame.x * scale,
						y: top + atom.frame.y * scale,
						width: atom.frame.width * scale,
						height:
							atom.frame.height *
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
		onCleanup(() => resize.disconnect());
	},
	{ flush: 'post' },
);
</script>

<!--
  Typeset atoms drawn at their own size, scaled down to fit a narrower
  frame and centred (CanonMathView). With `morphs`, a change animates
  through CanonMathMorph.
-->
<template>
	<div
		v-if="morphs"
		class="canon-math-view canon-math-view--morph"
		:class="{
			'canon-math-view--faint': faint,
			'canon-math-view--mono': mono,
		}"
		v-bind="$attrs"
		:style="$attrs.style ?? morphStyle"
	>
		<svg role="img" :aria-label="label"><g ref="group"></g></svg>
	</div>
	<svg
		v-else
		ref="svg"
		class="canon-math-view"
		:class="{
			'canon-math-view--faint': faint,
			'canon-math-view--mono': mono,
		}"
		role="img"
		:aria-label="label"
		v-bind="$attrs"
	></svg>
</template>
