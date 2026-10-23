<script lang="ts" module>
	export type CanonLoaderMode =
		'snake' | 'comet' | 'dot' | 'twin' | 'thinking';
</script>

<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-loader.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'children'
	> {
		/** Default snake. thinking swings back and forth. */
		mode?: CanonLoaderMode;
		/** Runs anticlockwise; thinking ignores it. */
		reverse?: boolean;
		/** Cell side in px; default 8. */
		cell?: number;
		/** Gap between cells in px; default 2. */
		gap?: number;
	}

	let {
		mode,
		reverse,
		cell = 8,
		gap = 2,
		class: className,
		...rest
	}: Props = $props();
</script>

<!--
  @component
  3 x 3 cell loader in the current colour, the web nds-loader: a lit head
  runs clockwise round the eight outer cells over a lit centre.
-->
<div
	class={[
		'canon-loader',
		`canon-loader--${mode || 'snake'}`,
		reverse && 'canon-loader--reverse',
		className,
	]}
	role="status"
	aria-label="Loading"
	style="--canon-loader-cell: {cell}px; --canon-loader-gap: {gap}px"
	{...rest}
>
	<span style="--i: 0"></span>
	<span style="--i: 1"></span>
	<span style="--i: 2"></span>
	<span style="--i: 7"></span>
	<i></i>
	<span style="--i: 3"></span>
	<span style="--i: 6"></span>
	<span style="--i: 5"></span>
	<span style="--i: 4"></span>
</div>
