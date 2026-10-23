<script lang="ts" module>
	export type CanonRowForm = 'plain' | 'flush' | 'stacked';
</script>

<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { HTMLAttributes } from 'svelte/elements';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-row.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'title' | 'children'
	> {
		title: string;
		detail?: string;
		/** Shown before the title in a plain row. */
		icon?: Snippet;
		/**
		 * plain: the control keeps air around it. flush: the control meets the
		 * row's top, bottom and trailing edge behind a hairline. stacked: the
		 * control spans the row below the label.
		 */
		form?: CanonRowForm;
		/** Longest title among sibling rows, so a grid of rows stacks as one. */
		sizingTitle?: string;
		/** The control; gets the title's id for aria-labelledby. */
		children?: Snippet<[titleId: string]>;
	}

	let {
		title,
		detail,
		icon,
		form = 'plain',
		sizingTitle,
		children,
		class: className,
		...rest
	}: Props = $props();

	const uid = $props.id();
	const titleId = `${uid}-title`;
</script>

<!--
  @component
  Label beside a control. A row too narrow for both puts the control below
  the label.
-->
<div class={['canon-row', `canon-row--${form}`, className]} {...rest}>
	<div class="canon-row-label">
		{#if icon && form === 'plain'}
			<span class="canon-row-icon" aria-hidden="true"
				>{@render icon()}</span
			>
		{/if}
		<div class="canon-row-text">
			<span class="canon-row-title" id={titleId}>{title}</span
			>
			{#if detail}
				<span class="canon-row-detail">{detail}</span>
			{/if}
			{#if sizingTitle}
				<span
					class="canon-row-title canon-row-sizer"
					aria-hidden="true">{sizingTitle}</span
				>
			{/if}
		</div>
	</div>
	{#if children}
		<div class="canon-row-control">{@render children(titleId)}</div>
	{/if}
</div>
