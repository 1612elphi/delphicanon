<script lang="ts" module>
	/** neutral: no state. off: disabled module. on and warning light the leading edge. */
	export type CanonSidebarLight = 'neutral' | 'off' | 'on' | 'warning';
</script>

<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { HTMLAttributes } from 'svelte/elements';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-sidebar-row.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLAnchorElement | HTMLButtonElement>,
		'title' | 'children'
	> {
		title: string;
		/** Rendered in the 44 px icon cell; the consumer supplies it. */
		icon?: Snippet;
		/** Default neutral. */
		light?: CanonSidebarLight;
		/** The current page: filled in primary, `aria-current="page"`. */
		selected?: boolean;
		/** Makes the row a link; without it the row is a button. */
		href?: string;
		onClick?: (event: MouseEvent) => void;
	}

	let {
		title,
		icon,
		light = 'neutral',
		selected,
		href,
		onClick,
		class: className,
		onclick,
		...rest
	}: Props = $props();

	function click(
		event: MouseEvent & {
			currentTarget: HTMLAnchorElement | HTMLButtonElement;
		},
	) {
		onclick?.(event);
		onClick?.(event);
	}
</script>

{#snippet cells()}
	<span class="canon-sidebar-row-icon" aria-hidden="true">
		{@render icon?.()}
	</span>
	<span class="canon-sidebar-row-title">{title}</span>
{/snippet}

<!-- @component One navigation row of a CanonSidebar: an icon cell and a title cell (SidebarRow). -->
{#if href}
	<a
		{href}
		class={[
			'canon-sidebar-row',
			`canon-sidebar-row--${light}`,
			className,
		]}
		aria-current={selected ? 'page' : undefined}
		onclick={click}
		{...rest}
	>
		{@render cells()}
	</a>
{:else}
	<button
		type="button"
		class={[
			'canon-sidebar-row',
			`canon-sidebar-row--${light}`,
			className,
		]}
		aria-current={selected ? 'page' : undefined}
		onclick={click}
		{...rest}
	>
		{@render cells()}
	</button>
{/if}
