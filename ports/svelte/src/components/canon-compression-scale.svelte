<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import type { Attachment } from 'svelte/attachments';
	import {
		barLabel,
		compressionScale,
		labelSpare,
	} from '@canon/lib/compression.ts';
	import { springEasing } from '@canon/lib/motion.ts';
	import CanonBar from './canon-bar.svelte';
	import CanonFigure from './canon-figure.svelte';
	import CanonLoader from './canon-loader.svelte';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-compression-scale.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'children'
	> {
		/** The original's size in bytes; 0 before a file. */
		before: number;
		/** The result's size in bytes; 0 before a result. */
		after: number;
		/** The result bar's label. */
		format: string;
		/** Shows the loader beside the figure. */
		working?: boolean;
	}

	let {
		before,
		after,
		format,
		working,
		class: className,
		...rest
	}: Props = $props();

	// the iOS bar spring: 0.6 s, damping 0.7
	const style = `--canon-compression-scale-easing: ${springEasing(0.7)}`;

	/**
	 * The label sits inside the fill when it fits with 20 px to spare, else
	 * after it. A new label text re-runs it, as its width changes.
	 */
	function place(share: number, _label: string): Attachment<HTMLElement> {
		return (bar) => {
			const shown = bar.querySelector<HTMLElement>(
				'.canon-compression-scale-label',
			)!;
			const update = () =>
				bar.toggleAttribute(
					'data-inside',
					bar.clientWidth * share >=
						shown.offsetWidth + labelSpare,
				);
			update();
			const observer = new ResizeObserver(update);
			observer.observe(bar);
			return () => observer.disconnect();
		};
	}

	const scale = $derived(compressionScale(before, after));
	const colour = $derived(
		scale.grew
			? 'var(--canon-destructive)'
			: 'var(--canon-primary)',
	);
	const bars = $derived([
		{
			label: barLabel('Original', before),
			share: 1,
			fill: 'var(--canon-muted)',
			ink: 'var(--canon-foreground)',
		},
		{
			label: barLabel(format, scale.known ? after : 0),
			share: scale.share,
			fill: colour,
			ink: 'var(--canon-primary-foreground)',
		},
	]);
</script>

<!-- @component Two bars to one scale, the original's bytes over the result's, with the saving as a figure. -->
<div class={['canon-compression-scale', className]} {style} {...rest}>
	<div class="canon-compression-scale-top">
		{#if working}
			<CanonLoader
				class="canon-compression-scale-loader"
				cell={5}
				gap={1}
			/>
		{/if}
		<CanonFigure text={scale.figure} unit={scale.unit} {colour} />
	</div>
	{#each bars as bar, index (index)}
		<div
			class="canon-compression-scale-bar"
			style="--canon-compression-scale-share: {Math.min(
				Math.max(bar.share, 0),
				1,
			)}; --canon-compression-scale-ink: {bar.ink}"
			{@attach place(bar.share, bar.label)}
		>
			<CanonBar
				share={bar.share}
				fill={bar.fill}
				track="transparent"
			/>
			<span class="canon-compression-scale-label"
				>{bar.label}</span
			>
		</div>
	{/each}
</div>
