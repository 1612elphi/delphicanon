<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import CanonButton from './canon-button.svelte';
	import { splitForMiddle } from '@canon/lib/files.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-file-cell.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'children'
	> {
		/** As the file input's accept attribute; empty takes any file. */
		accept?: string;
		labelledBy?: string;
		disabled?: boolean;
		onChange?: (file: File) => void;
	}

	let {
		accept,
		labelledBy,
		disabled,
		onChange,
		class: className,
		...rest
	}: Props = $props();

	// ponytail: no clear(); re-render the cell to empty it
	let file = $state<File>();
	let input = $state<HTMLInputElement>();

	const parts = $derived(file ? splitForMiddle(file.name) : undefined);

	function picked(event: Event & { currentTarget: HTMLInputElement }) {
		const chosen = event.currentTarget.files?.[0];
		event.currentTarget.value = '';
		if (!chosen) return;
		file = chosen;
		onChange?.(chosen);
	}
</script>

<!-- @component File name beside a Choose cell. -->
<div
	class={['canon-file-cell', className]}
	role="group"
	aria-labelledby={labelledBy}
	{...rest}
>
	<span
		class={[
			'canon-file-cell-name',
			!parts && 'canon-file-cell-name--none',
		]}
	>
		{#if parts}
			<span class="canon-file-cell-head">{parts[0]}</span>
			<span class="canon-file-cell-tail">{parts[1]}</span>
		{:else}
			None
		{/if}
	</span>
	<CanonButton
		kind="cell"
		text="Choose"
		{disabled}
		onClick={() => input?.click()}
	/>
	<input
		type="file"
		class="canon-file-cell-input"
		{accept}
		hidden
		bind:this={input}
		onchange={picked}
	/>
</div>
