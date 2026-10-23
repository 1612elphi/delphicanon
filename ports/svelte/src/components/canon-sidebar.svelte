<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { HTMLAttributes } from 'svelte/elements';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-sidebar.css';

	interface Props extends HTMLAttributes<HTMLElement> {
		/**
		 * true: the icon rail. false: full width at every size. Unset: the rail
		 * inside a `canon-window` container narrower than 640 px.
		 */
		collapsed?: boolean;
		/** 32 px rows at subheadline size, for dense navigation. */
		compact?: boolean;
		/** A picture above the rows that does not scroll with them. */
		hero?: Snippet;
		/** CanonSidebarRows, and CanonHeadings between groups. */
		children?: Snippet;
	}

	let {
		collapsed,
		compact,
		hero,
		children,
		class: className,
		...rest
	}: Props = $props();
</script>

<!--
  @component
  The window's navigation column (Sidebar): 240 px of 44 px rows on the
  muted background, the gaps between rows and cells showing the border
  colour, a frame-width rule on the trailing edge.
-->
<nav
	class={[
		'canon-sidebar',
		collapsed === true && 'canon-sidebar--collapsed',
		collapsed === false && 'canon-sidebar--expanded',
		compact && 'canon-sidebar--compact',
		className,
	]}
	{...rest}
>
	{#if hero}
		<div class="canon-sidebar-hero">{@render hero()}</div>
	{/if}
	<div class="canon-sidebar-scroll">
		<div class="canon-sidebar-rows">{@render children?.()}</div>
	</div>
</nav>
