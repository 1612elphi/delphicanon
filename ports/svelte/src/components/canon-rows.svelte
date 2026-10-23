<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { HTMLAttributes } from 'svelte/elements';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-rows.css';

	interface Props extends HTMLAttributes<HTMLDivElement> {
		/** Draws the 2 px tool frame around the rows. */
		framed?: boolean;
		children?: Snippet;
	}

	let { framed, children, class: className, ...rest }: Props = $props();
</script>

<!-- @component Rows separated by hairlines: the gaps show the border colour. -->
<div
	class={['canon-rows', framed && 'canon-rows--framed', className]}
	{...rest}
>
	{@render children?.()}
</div>
