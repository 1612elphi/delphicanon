<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-empty-row.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'children'
	> {
		text: string;
	}

	let { text, class: className, ...rest }: Props = $props();
</script>

<div class={['canon-empty-row', className]} {...rest}>{text}</div>
