<script lang="ts">
import type { Key } from '@canon/lib/math/expression.ts';

/** Opens a CanonMathField from outside it, as `field.edit(then:)` does. */
export class CanonMathFieldHandle {
	field?: { edit: (keys: Key[]) => void };

	/** Opens the keypad sheet, then types `keys`. */
	edit = (keys: Key[] = []) => this.field?.edit(keys);
}
</script>

<script setup lang="ts">
import {
	computed,
	onBeforeUnmount,
	ref,
	shallowRef,
	useTemplateRef,
} from 'vue';
import { Expression, layoutRow } from '@canon/lib/math/expression.ts';
import { canvasMetrics } from '@canon/lib/math/measure.ts';
import { Typesetter } from '@canon/lib/math/typeset.ts';
import { vPress } from '../lib/press.ts';
import { keyboard } from '../lib/lucide.ts';
import CanonIcon from './canon-icon.vue';
import CanonMathInput from './canon-math-input.vue';
import CanonMathView from './canon-math-view.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-field.css';

defineOptions({ inheritAttrs: false });

const props = defineProps<{
	/** nerdamer syntax. */
	text?: string;
	/** The letter the keypad offers first, and the variable of derivatives, integrals and limits. */
	variable?: string;
	/** Shown faint while the text is empty, in the same syntax. */
	placeholder?: string;
	/** Font size in px; default 22. */
	size?: number;
	/** Every edit made in the keypad sheet. */
	onChange?: (text: string) => void;
	/** The sheet closed, with the text. */
	onCompletion?: (text: string) => void;
	/** Lets insert keys beside the field open it and type. */
	handle?: CanonMathFieldHandle;
}>();

const editing = ref(false);
const pendingKeys = shallowRef<Key[]>([]);
const edited = ref<{ text: string; over?: string }>();
const button = useTemplateRef<HTMLButtonElement>('button');

/** The last edit, until the owner passes a different text. */
const text = computed(() => {
	const last = edited.value;
	return last && last.over === props.text
		? last.text
		: (props.text ?? '');
});

const variable = computed(() => props.variable ?? 'x');

const box = computed(() => {
	const shown = text.value || (props.placeholder ?? '');
	return layoutRow(
		new Typesetter(canvasMetrics, props.size ?? 22, 'result'),
		new Expression(shown, variable.value).root,
		{ variable: variable.value },
	);
});

function edit(keys: Key[] = []) {
	if (editing.value) return;
	pendingKeys.value = keys;
	editing.value = true;
}

const self = { edit };
const handle = props.handle;
if (handle) handle.field = self;
onBeforeUnmount(() => {
	if (handle?.field === self) handle.field = undefined;
});

function changed(next: string) {
	edited.value = { text: next, over: props.text };
	props.onChange?.(next);
}

function closed(next: string) {
	edited.value = { text: next, over: props.text };
	editing.value = false;
	props.onCompletion?.(next);
	button.value?.focus({ preventScroll: true });
}
</script>

<!--
  An expression typeset in a flush cell; a click opens the keypad sheet
  (CanonMathField). `onChange` runs on every edit made there, `onCompletion`
  when the sheet closes.
-->
<template>
	<button
		ref="button"
		v-press
		type="button"
		class="canon-math-field"
		:class="{ 'canon-math-field--editing': editing }"
		aria-label="Expression"
		aria-haspopup="dialog"
		v-bind="$attrs"
		@click="edit()"
	>
		<CanonMathView :box="box" :faint="!text" :label="text" />
		<span class="canon-math-field-glyph"
			><CanonIcon :svg="keyboard"
		/></span>
	</button>
	<CanonMathInput
		v-if="editing"
		:text="text"
		:variable="variable"
		:keys="pendingKeys"
		:source="button ?? undefined"
		:on-change="changed"
		:on-close="closed"
	/>
</template>
