<script lang="ts" module>
	/**
	 * FluoWrite's full stop is 8.2 units wide against the colon's 21.8, and the
	 * digits have no side bearing; padding either side seats it in a slot a
	 * little wider than a colon's.
	 */
	export const stopPadding = ((21.8 - 8.2) / 2 + 4) / 100;
</script>

<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import {
		hasDigits,
		hundredths,
		timecodeRuns,
	} from '@canon/lib/timecode.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-timecode.css';

	interface Props extends HTMLAttributes<HTMLSpanElement> {
		/** Seconds to show; none shows hyphens. Ignored when `text` is set. */
		seconds?: number | null;
		/**
		 * A timecode already formatted. One without digits, or null, shows
		 * hyphens in the shape of the last one.
		 */
		text?: string | null;
		/** Replaces minutes, seconds and hundredths, for SMPTE timecode. */
		format?: (seconds: number) => string;
		/** Font size in px; default 44. */
		size?: number;
		/** CSS colour of the halo that keeps the digits clear of what runs under them; default the muted colour. */
		halo?: string;
		/** What the counter measures, for assistive technology. */
		label?: string;
	}

	let {
		seconds,
		text,
		format,
		size = 44,
		halo,
		label,
		class: className,
		...rest
	}: Props = $props();

	let lastShape = hundredths(0);

	const display = $derived.by(() => {
		const shape =
			text === undefined
				? (format ?? hundredths)(seconds ?? 0)
				: text;
		const blank =
			text === undefined
				? seconds === undefined || seconds === null
				: !hasDigits(text);
		// a null text keeps the last shape, as hyphens
		if (shape) lastShape = shape;
		return { shape: lastShape, blank };
	});
	const runs = $derived(timecodeRuns(display.shape, display.blank));
	const spoken = $derived(
		display.blank
			? undefined
			: runs.map((run) => run.text).join(''),
	);
</script>

<!--
  @component
  Counter in the segment font, for the corner of a waveform band. Leading
  zeros that carry no value are dimmed.
-->
<span
	class={['canon-timecode', className]}
	style:--canon-timecode-size="{size}px"
	style:--canon-timecode-stop="{stopPadding * size}px"
	style:--canon-timecode-halo={halo}
	role="timer"
	aria-label={label}
	{...rest}
>
	<span class="canon-timecode-halo" aria-hidden="true"
		>{#each runs as run, i (i)}<span
				class={[run.stop && 'canon-timecode-stop']}
				>{run.text}</span
			>{/each}</span
	>
	<span class="canon-timecode-digits" aria-hidden="true"
		>{#each runs as run, i (i)}<span
				class={[
					run.stop && 'canon-timecode-stop',
					run.dim && 'canon-timecode-dim',
				]}>{run.text}</span
			>{/each}</span
	>
	{#if spoken}
		<span class="canon-timecode-spoken">{spoken}</span>
	{/if}
</span>
