<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-rule.css';

	interface Props extends HTMLAttributes<HTMLDivElement> {
		vertical?: boolean;
	}

	let { vertical, class: className, ...rest }: Props = $props();
</script>

<div
	class={['canon-rule', vertical && 'canon-rule--vertical', className]}
	role="separator"
	aria-orientation={vertical ? 'vertical' : 'horizontal'}
	{...rest}
></div>
