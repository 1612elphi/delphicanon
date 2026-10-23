<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import CanonIcon from './canon-icon.svelte';
	import { chevronsUpDown } from '../lib/control-icons.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-menu-cell.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'children' | 'placeholder'
	> {
		items: string[];
		/** Undefined shows the placeholder: a value set elsewhere that matches no choice. */
		selected?: number;
		/** Default an em dash. */
		placeholder?: string;
		labelledBy?: string;
		label?: string;
		disabled?: boolean;
		onChange?: (index: number) => void;
	}

	let {
		items,
		selected: given,
		placeholder = '—',
		labelledBy,
		label,
		disabled,
		onChange,
		class: className,
		...rest
	}: Props = $props();

	let picked = $state<{ index: number; over: number | undefined }>();

	const selected = $derived(
		picked && picked.over === given ? picked.index : given,
	);
	const title = $derived(
		selected === undefined ? undefined : items[selected],
	);

	function pick(event: Event & { currentTarget: HTMLSelectElement }) {
		const index = Number(event.currentTarget.value);
		if (index === selected) return;
		picked = { index, over: given };
		onChange?.(index);
	}
</script>

<!--
  @component
  A flush cell that shows one choice and opens the system menu of all of
  them: a native select laid invisibly over the cell.
-->
<div
	class={[
		'canon-menu-cell',
		disabled && 'canon-menu-cell--disabled',
		className,
	]}
	{...rest}
>
	<span class="canon-menu-cell-title">{title ? title : placeholder}</span>
	<span class="canon-menu-cell-icon" aria-hidden="true"
		><CanonIcon svg={chevronsUpDown} /></span
	>
	<select
		class="canon-menu-cell-select"
		aria-labelledby={labelledBy}
		aria-label={label}
		{disabled}
		onchange={pick}
	>
		{#if !title}
			<option value="" disabled selected hidden
				>{placeholder}</option
			>
		{/if}
		{#each items as choice, index (index)}
			<option
				value={String(index)}
				selected={index === selected}>{choice}</option
			>
		{/each}
	</select>
</div>
