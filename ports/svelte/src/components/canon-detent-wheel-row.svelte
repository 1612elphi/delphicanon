<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { HTMLAttributes } from 'svelte/elements';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-detent-wheel-row.css';

	interface Props extends HTMLAttributes<HTMLDivElement> {
		/** From CanonDetentWheel's children: 1 on the centre line, 0 a row or more away. */
		focus: number;
		children?: Snippet;
	}

	let { focus, children, class: className, ...rest }: Props = $props();
</script>

<!--
  @component
  A centred label for a CanonDetentWheel row that brightens as it nears the centre line.
-->
<div
	class={['canon-detent-wheel-row', className]}
	style="--canon-detent-focus: {focus}"
	{...rest}
>
	{@render children?.()}
</div>
