<script lang="ts" module>
	export type CanonStatusTone = 'ok' | 'warn' | 'muted';
</script>

<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-status.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'children'
	> {
		text: string;
		tone: CanonStatusTone;
		/** A padded row of its own for a CanonRows. */
		row?: boolean;
	}

	let { text, tone, row, class: className, ...rest }: Props = $props();
</script>

<!-- @component A short state word in the colour of its tone: ok, warn or muted. -->
<div
	class={[
		'canon-status',
		`canon-status--${tone}`,
		row && 'canon-status--row',
		className,
	]}
	role="status"
	{...rest}
>
	{text}
</div>
