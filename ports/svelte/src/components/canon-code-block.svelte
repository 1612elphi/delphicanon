<script lang="ts">
	import { onDestroy } from 'svelte';
	import type { HTMLAttributes } from 'svelte/elements';
	import { press } from '../lib/press.ts';
	import { canonToast } from '../lib/toast-store.svelte.ts';
	import { check, copy as copyIcon } from '../lib/control-icons.ts';
	import { flashSeconds } from './canon-button.svelte';
	import CanonIcon from './canon-icon.svelte';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-code-block.css';

	interface Props extends HTMLAttributes<HTMLDivElement> {
		code: string;
		/** Shown uppercased in a heading bar above the code; without it the copy button sits below. */
		language?: string;
		/** Taller code scrolls inside the block. */
		maxHeight?: number;
	}

	let {
		code,
		language,
		maxHeight,
		class: className,
		...rest
	}: Props = $props();

	let copied = $state(false);
	let destroyed = false;
	let timer: number | undefined;

	async function copy() {
		try {
			await canonToast.write(code);
		} catch {
			return;
		}
		if (destroyed) return;
		copied = true;
		window.clearTimeout(timer);
		timer = window.setTimeout(() => {
			copied = false;
		}, flashSeconds * 1000);
	}

	onDestroy(() => {
		destroyed = true;
		clearTimeout(timer);
	});
</script>

<!--
  @component
  Monospaced, selectable code with a copy button. Lines do not wrap; the
  block scrolls sideways.
-->
<div
	class={[
		'canon-code-block',
		language && 'canon-code-block--titled',
		className,
	]}
	{...rest}
>
	<div class="canon-code-block-bar">
		{#if language}
			<span class="canon-code-block-language">{language}</span
			>
		{/if}
		<button
			type="button"
			class={[
				'canon-code-block-copy',
				copied && 'canon-code-block-copy--copied',
			]}
			aria-label="Copy code"
			onclick={copy}
			{@attach press}
		>
			<CanonIcon svg={copied ? check : copyIcon} />
		</button>
	</div>
	<!-- svelte-ignore a11y_no_noninteractive_tabindex -->
	<pre
		class="canon-code-block-code"
		tabindex="0"
		style:max-block-size={maxHeight === undefined
			? undefined
			: `${maxHeight}px`}>{code}</pre>
</div>
