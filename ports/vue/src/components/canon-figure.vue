<script setup lang="ts">
import { computed, useTemplateRef, watch } from 'vue';
import { changedFromEnd, leadingNumber } from '@canon/lib/figure.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-figure.css';

const props = withDefaults(
	defineProps<{
		text: string;
		/** Set smaller after the figure. */
		unit?: string;
		/** Font size in px; default 40. */
		size?: number;
		/** CSS colour; default the primary colour. A change fades. */
		colour?: string;
		/** Outline and soft shadow in this CSS colour, for a figure over a picture. */
		halo?: string;
		/** False shows a new text without rolling. */
		animated?: boolean;
	}>(),
	{ animated: undefined },
);

const rollMs = 350;
const easing = 'cubic-bezier(0.2, 0.9, 0.3, 1)';

function still() {
	return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

const style = computed(() => {
	const edge = `0 0 1px ${props.halo}`;
	return {
		'--canon-figure-size': `${props.size ?? 40}px`,
		'--canon-figure-colour': props.colour || undefined,
		textShadow: props.halo
			? `${edge}, ${edge}, ${edge}, ${edge}, 0 3px 5px ${props.halo}`
			: undefined,
	};
});

const chars = useTemplateRef<HTMLElement>('chars');
let before: string | undefined;

// rebuilds the characters; changed ones roll in the direction the number moved
watch(
	[chars, () => props.text, () => props.animated !== false],
	([element, text, animated]) => {
		if (!element) return;
		const previous = before;
		before = text;
		element.replaceChildren(
			...[...text].map((char) => {
				const span = document.createElement('span');
				span.className = 'canon-figure-char';
				span.textContent = char;
				return span;
			}),
		);
		if (
			previous === undefined ||
			previous === text ||
			!animated ||
			still()
		)
			return;
		// up rolls new characters in from below
		const up =
			leadingNumber(text) >= leadingNumber(previous) ? 1 : -1;
		const spans = [...element.children] as HTMLElement[];
		for (const { index, old } of changedFromEnd(previous, text)) {
			const span = spans[index]!;
			span.animate(
				[
					{
						transform: `translateY(${up * 60}%)`,
						opacity: 0,
						filter: 'blur(2px)',
					},
					{
						transform: 'none',
						opacity: 1,
						filter: 'none',
					},
				],
				{ duration: rollMs, easing },
			);
			if (old === undefined) continue;
			const ghost = document.createElement('span');
			ghost.className = 'canon-figure-ghost';
			ghost.textContent = old;
			span.append(ghost);
			ghost.animate(
				[
					{
						transform: 'none',
						opacity: 1,
						filter: 'none',
					},
					{
						transform: `translateY(${-up * 60}%)`,
						opacity: 0,
						filter: 'blur(2px)',
					},
				],
				{ duration: rollMs, easing, fill: 'forwards' },
			).finished.then(
				() => ghost.remove(),
				() => ghost.remove(),
			);
		}
	},
	{ flush: 'post' },
);
</script>

<!-- A calculated figure whose changed characters roll. -->
<template>
	<div class="canon-figure" :style="style">
		<span class="canon-figure-said">{{ text }}{{ unit }}</span>
		<span
			ref="chars"
			class="canon-figure-text"
			aria-hidden="true"
		></span>
		<span
			v-if="unit"
			class="canon-figure-unit"
			aria-hidden="true"
			>{{ unit }}</span
		>
	</div>
</template>
