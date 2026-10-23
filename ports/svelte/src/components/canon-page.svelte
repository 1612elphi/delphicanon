<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { HTMLAttributes } from 'svelte/elements';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-page.css';

	interface Props extends HTMLAttributes<HTMLDivElement> {
		/** Widest a section gets, in px; null for no cap. Default 720. */
		maxWidth?: number | null;
		children?: Snippet;
	}

	let {
		maxWidth = 720,
		children,
		class: className,
		...rest
	}: Props = $props();
</script>

<!--
  @component
  Scrolling tool body. Sections are centred, capped at maxWidth and inset by
  the panel padding; a CanonCanvas section spans the full width instead
  (CanonPage and CanonPaddedSection).
-->
<div
	class={['canon-page', className]}
	style={maxWidth === null
		? undefined
		: `--canon-page-max-width: ${maxWidth}px`}
	{...rest}
>
	{@render children?.()}
</div>
