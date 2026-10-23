<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { HTMLAttributes } from 'svelte/elements';
	import CanonButton from './canon-button.svelte';
	import { Minus, Plus } from '../lib/control-icons.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-stepper.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'children'
	> {
		/** Called with -1 or 1; repeats while a button is held. */
		onStep: (direction: -1 | 1) => void;
		disabled?: boolean;
		/** The middle cell, usually a field and its unit. A click anywhere in it focuses the field. */
		children?: Snippet;
	}

	let {
		onStep,
		disabled,
		children,
		class: className,
		...rest
	}: Props = $props();
</script>

<!-- @component Minus and plus cells either side of a field's cell, divided by hairlines. -->
<div class={['canon-stepper', className]} {...rest}>
	<CanonButton
		class="canon-stepper-minus"
		kind="cell"
		icon={Minus}
		label="Decrease"
		repeats
		{disabled}
		onClick={() => onStep(-1)}
	/>
	<label class="canon-stepper-centre">{@render children?.()}</label>
	<CanonButton
		class="canon-stepper-plus"
		kind="cell"
		icon={Plus}
		label="Increase"
		repeats
		{disabled}
		onClick={() => onStep(1)}
	/>
</div>
