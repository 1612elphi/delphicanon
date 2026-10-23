<script lang="ts" module>
	import type { Key } from '@canon/lib/math/expression.ts';

	/** Opens a CanonMathField from outside it, as `field.edit(then:)` does. */
	export class CanonMathFieldHandle {
		field?: { edit(keys: Key[]): void };

		/** Opens the keypad sheet, then types `keys`. */
		edit = (keys: Key[] = []) => this.field?.edit(keys);
	}
</script>

<script lang="ts">
	import type { HTMLButtonAttributes } from 'svelte/elements';
	import { press } from '../lib/press.ts';
	import { keyboard } from '../lib/control-icons.ts';
	import CanonIcon from './canon-icon.svelte';
	import CanonMathInput from './canon-math-input.svelte';
	import CanonMathView from './canon-math-view.svelte';
	import { Expression, layoutRow } from '@canon/lib/math/expression.ts';
	import { canvasMetrics } from '@canon/lib/math/measure.ts';
	import { Typesetter } from '@canon/lib/math/typeset.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-math-field.css';

	interface Props extends HTMLButtonAttributes {
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
	}

	let {
		text: givenText,
		variable = 'x',
		placeholder,
		size = 22,
		onChange,
		onCompletion,
		handle,
		class: className,
		onclick,
		...rest
	}: Props = $props();

	let editing = $state(false);
	let pendingKeys = $state.raw<Key[]>([]);
	let edited = $state.raw<{ text: string; over?: string }>();
	let button = $state<HTMLButtonElement>();

	/** The last edit, until the owner passes a different text. */
	const text = $derived(
		edited && edited.over === givenText
			? edited.text
			: (givenText ?? ''),
	);

	const box = $derived(
		layoutRow(
			new Typesetter(canvasMetrics, size, 'result'),
			new Expression(text || (placeholder ?? ''), variable)
				.root,
			{ variable },
		),
	);

	function edit(keys: Key[] = []) {
		if (editing) return;
		pendingKeys = keys;
		editing = true;
	}

	$effect(() => {
		const owner = handle;
		if (!owner) return;
		const field = { edit };
		owner.field = field;
		return () => {
			if (owner.field === field) owner.field = undefined;
		};
	});

	function open(
		event: MouseEvent & { currentTarget: HTMLButtonElement },
	) {
		onclick?.(event);
		edit();
	}

	function changed(next: string) {
		edited = { text: next, over: givenText };
		onChange?.(next);
	}

	function closed(next: string) {
		edited = { text: next, over: givenText };
		editing = false;
		onCompletion?.(next);
		button?.focus({ preventScroll: true });
	}
</script>

<!--
  @component
  An expression typeset in a flush cell; a click opens the keypad sheet
  (CanonMathField). `onChange` runs on every edit made there, `onCompletion`
  when the sheet closes.
-->
<button
	type="button"
	class={[
		'canon-math-field',
		editing && 'canon-math-field--editing',
		className,
	]}
	aria-label="Expression"
	aria-haspopup="dialog"
	bind:this={button}
	onclick={open}
	{@attach press}
	{...rest}
>
	<CanonMathView {box} faint={!text} label={text} />
	<span class="canon-math-field-glyph"><CanonIcon svg={keyboard} /></span>
</button>
{#if editing}
	<CanonMathInput
		{text}
		{variable}
		keys={pendingKeys}
		source={button}
		onChange={changed}
		onClose={closed}
	/>
{/if}
