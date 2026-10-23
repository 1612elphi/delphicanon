<script lang="ts">
export type CanonValueLineLayout = 'beside' | 'above' | 'wrapping' | 'numbered';

const dash = '—';
</script>

<script setup lang="ts">
import { computed, useTemplateRef, watch } from 'vue';
import { vPress } from '../lib/press.ts';
import { toast } from '../lib/toast-store.ts';
import { copy as copySvg } from '../lib/lucide.ts';
import CanonIcon from './canon-icon.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-value-line.css';

const props = defineProps<{
	label: string;
	/** Null or undefined shows a dash and turns copying off. */
	value?: string | null;
	/**
	 * beside: the label in a column `labelWidth` wide, the value on one line.
	 * above: the label over the value. wrapping: the label as wide as it is,
	 * the value wrapping by character. numbered: a list index as the label.
	 */
	layout?: CanonValueLineLayout;
	/** Width of the label column in px for `beside`; fit it to the longest label among sibling lines. */
	labelWidth?: number;
	/** For `numbered`: a long value wraps by character instead of being cut off. */
	wraps?: boolean;
	/** Seconds after a change before the new value fades in; unset changes it at once. */
	fadeDelay?: number;
	/** Marks the chosen line of a list. */
	lit?: boolean;
	/** CSS colour for each character of the value; unset sets the value in one colour. */
	tint?: (character: string) => string;
	disabled?: boolean;
}>();

const layout = computed(() => props.layout ?? 'beside');
const shown = computed(() => props.value ?? dash);
const disabled = computed(() => props.disabled || props.value == null);
const characters = computed(() => {
	const { tint } = props;
	return tint
		? [...shown.value].map((character) => ({
				character,
				style: { color: tint(character) },
			}))
		: undefined;
});
const ariaLabel = computed(() =>
	layout.value === 'numbered'
		? shown.value
		: `${props.label} ${shown.value}`,
);

const copy = () => void toast.copy(shown.value);

// the old value stays for the delay, then crossfades to the new one
const valueElement = useTemplateRef<HTMLElement>('valueElement');
watch(
	shown,
	(text, before) => {
		const element = valueElement.value;
		const delay = props.fadeDelay;
		if (!element || delay === undefined || before === text) return;
		if (
			window.matchMedia('(prefers-reduced-motion: reduce)')
				.matches
		)
			return;
		const ghost = document.createElement('span');
		ghost.className =
			'canon-value-line-value canon-value-line-ghost';
		ghost.textContent = before;
		ghost.setAttribute('aria-hidden', 'true');
		Object.assign(ghost.style, {
			insetInlineStart: `${element.offsetLeft}px`,
			insetBlockStart: `${element.offsetTop}px`,
			inlineSize: `${element.offsetWidth}px`,
		});
		element.after(ghost);
		const duration =
			parseFloat(
				getComputedStyle(element).getPropertyValue(
					'--canon-value-line-fade',
				),
			) || 250;
		const timing = { duration, delay: delay * 1000 };
		element.animate(
			{ opacity: [0, 1] },
			{ ...timing, fill: 'backwards' },
		);
		ghost.animate(
			{ opacity: [1, 0] },
			{ ...timing, fill: 'forwards' },
		)
			.finished.catch(() => undefined)
			.finally(() => ghost.remove());
	},
	{ flush: 'post' },
);
</script>

<!-- A name and a value in a flush cell; a tap copies the value and confirms with the toast. -->
<template>
	<button
		v-press
		type="button"
		class="canon-value-line"
		:class="[
			`canon-value-line--${layout}`,
			{
				'canon-value-line--wraps': wraps,
				'canon-value-line--lit': lit,
			},
		]"
		:style="{ '--canon-value-line-label': `${labelWidth ?? 48}px` }"
		:aria-label="ariaLabel"
		:aria-current="lit ? 'true' : undefined"
		:disabled="disabled"
		@click="copy"
	>
		<span class="canon-value-line-label">{{ label }}</span>
		<span ref="valueElement" class="canon-value-line-value"
			><template v-if="characters"
				><span
					v-for="(c, i) in characters"
					:key="i"
					:style="c.style"
					>{{ c.character }}</span
				></template
			><template v-else>{{ shown }}</template></span
		>
		<span class="canon-value-line-glyph" aria-hidden="true"
			><CanonIcon :svg="copySvg"
		/></span>
	</button>
</template>
