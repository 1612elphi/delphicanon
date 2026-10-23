<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import CanonStepper from './canon-stepper.svelte';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-big-number-field.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'children' | 'placeholder'
	> {
		/** The field's text; the tool parses it and sets it. */
		value?: string;
		placeholder?: string;
		/** Centred under the number. */
		unit?: string;
		/** Called with -1 or 1 by the step buttons (repeating while held) and the arrow keys. */
		onStep: (direction: -1 | 1) => void;
		/** Called on every edit with the typed text. */
		onInput?: (text: string) => void;
		/** Typing ended: the field lost focus or Return was pressed. */
		onEndEditing?: () => void;
		labelledBy?: string;
		label?: string;
		disabled?: boolean;
	}

	let {
		value,
		placeholder,
		unit,
		onStep,
		onInput,
		onEndEditing,
		labelledBy,
		label,
		disabled,
		class: className,
		...rest
	}: Props = $props();

	function key(
		event: KeyboardEvent & { currentTarget: HTMLInputElement },
	) {
		if (event.key === 'Enter') event.currentTarget.blur();
		if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown')
			return;
		event.preventDefault();
		onStep(event.key === 'ArrowUp' ? 1 : -1);
	}
</script>

<!-- @component A tool's main number, large and centred over its unit, between step buttons. -->
<CanonStepper
	class={['canon-big-number-field', className]}
	{onStep}
	{disabled}
	{...rest}
>
	<span class="canon-big-number-field-stack">
		<input
			type="text"
			class="canon-big-number-field-input"
			inputmode="decimal"
			enterkeyhint="done"
			autocomplete="off"
			spellcheck="false"
			{value}
			{placeholder}
			aria-labelledby={labelledBy}
			aria-label={label}
			{disabled}
			oninput={(event) =>
				onInput?.(event.currentTarget.value)}
			onkeydown={key}
			onblur={() => onEndEditing?.()}
		/>
		{#if unit}
			<span class="canon-big-number-field-unit">{unit}</span>
		{/if}
	</span>
</CanonStepper>
