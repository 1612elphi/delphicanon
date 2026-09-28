<script lang="ts">
/**
 * FluoWrite's full stop is 8.2 units wide against the colon's 21.8, and the
 * digits have no side bearing; padding either side seats it in a slot a
 * little wider than a colon's.
 */
export const stopPadding = ((21.8 - 8.2) / 2 + 4) / 100;
</script>

<script setup lang="ts">
import { computed } from 'vue';
import { hasDigits, hundredths, timecodeRuns } from '@canon/lib/timecode.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-timecode.css';

const props = withDefaults(
  defineProps<{
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
  }>(),
  { seconds: undefined, text: undefined },
);

let lastShape = hundredths(0);

const display = computed(() => {
  const { text, seconds, format } = props;
  const shape =
    text === undefined ? (format ?? hundredths)(seconds ?? 0) : text;
  const blank =
    text === undefined
      ? seconds === undefined || seconds === null
      : !hasDigits(text);
  // a null text keeps the last shape, as hyphens
  if (shape) lastShape = shape;
  return { shape: lastShape, blank };
});

const runs = computed(() =>
  timecodeRuns(display.value.shape, display.value.blank),
);

const spoken = computed(() =>
  display.value.blank ? undefined : runs.value.map((run) => run.text).join(''),
);

const style = computed(() => {
  const size = props.size ?? 44;
  return {
    '--canon-timecode-size': `${size}px`,
    '--canon-timecode-stop': `${stopPadding * size}px`,
    '--canon-timecode-halo': props.halo || undefined,
  };
});
</script>

<!--
  Counter in the segment font, for the corner of a waveform band. Leading
  zeros that carry no value are dimmed.
-->
<template>
  <span class="canon-timecode" :style="style" role="timer" :aria-label="label">
    <span class="canon-timecode-halo" aria-hidden="true"
      ><span
        v-for="(run, i) in runs"
        :key="i"
        :class="{ 'canon-timecode-stop': run.stop }"
        >{{ run.text }}</span
      ></span
    >
    <span class="canon-timecode-digits" aria-hidden="true"
      ><span
        v-for="(run, i) in runs"
        :key="i"
        :class="{
          'canon-timecode-stop': run.stop,
          'canon-timecode-dim': run.dim,
        }"
        >{{ run.text }}</span
      ></span
    >
    <span v-if="spoken" class="canon-timecode-spoken">{{ spoken }}</span>
  </span>
</template>
