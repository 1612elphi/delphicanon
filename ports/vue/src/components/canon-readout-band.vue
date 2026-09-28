<script lang="ts">
import type { CanonLamp } from './canon-lamps.vue';

/** What a readout band shows of a player. */
export interface CanonTransport {
  playhead?: number | null;
  playing?: boolean;
  /** Parked at `playhead`. */
  paused?: boolean;
  /** Capturing, for a record lamp. */
  recording?: boolean;
  looping?: boolean;
  /** Count of wraps; a change blinks the loop lamp. */
  loops?: number;
}

/** Height of the row under the strip in `below`. */
export const readoutRow = 44;

/** The band's height for a strip of a given height, in `below`. */
export function readoutBandHeight(strip: number) {
  return strip + readoutRow;
}
</script>

<script setup lang="ts">
import { computed } from 'vue';
import CanonLamps, { transportLamps } from './canon-lamps.vue';
import CanonTimecode from './canon-timecode.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-readout-band.css';

const props = withDefaults(
  defineProps<{
    transport: CanonTransport;
    /** Seconds the counter shows without a playhead; none shows hyphens. */
    idle?: number | null;
    /**
     * over: counter and lamps sit over the strip's bottom corners, a waveform
     * reads through them. below: they get a row of their own under the strip,
     * a filmstrip's frames stay clear.
     */
    readout?: 'over' | 'below';
    /** Which lamps the band has; every one is always present. */
    lamps?: readonly CanonLamp[];
    /** See CanonTimecode's `format`. */
    format?: (seconds: number) => string;
  }>(),
  { idle: undefined },
);

defineSlots<{
  /** The picture of the whole file: a waveform, a filmstrip. */
  default?: (props: { playhead: number | null | undefined }) => unknown;
}>();

const readout = computed(() => props.readout ?? 'over');

const lit = computed(() => {
  const { playing, paused, looping, recording } = props.transport;
  const lamps: CanonLamp[] = [];
  if (playing) lamps.push('play');
  if (paused) lamps.push('pause');
  if (looping) lamps.push('loop');
  if (recording) lamps.push('record');
  return lamps;
});

const flashes = computed(() => ({ loop: props.transport.loops ?? 0 }));
const seconds = computed(() => props.transport.playhead ?? props.idle);
const label = computed(() => {
  const { playhead } = props.transport;
  return playhead === undefined || playhead === null ? 'Length' : 'Position';
});
</script>

<!--
  A strip of the whole file under a counter and transport lamps: the banner
  of a media tool.
-->
<template>
  <div class="canon-readout-band" :class="`canon-readout-band--${readout}`">
    <div class="canon-readout-band-strip">
      <slot :playhead="transport.playhead" />
    </div>
    <div class="canon-readout-band-readout">
      <CanonLamps
        :lamps="lamps?.length ? lamps : transportLamps"
        :lit="lit"
        :flashes="flashes"
      />
      <CanonTimecode
        :seconds="seconds"
        :format="format"
        :size="readout === 'over' ? 44 : 30"
        :label="label"
      />
    </div>
  </div>
</template>
