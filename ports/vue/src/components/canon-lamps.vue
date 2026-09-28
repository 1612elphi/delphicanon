<script lang="ts">
export type CanonLamp = 'play' | 'pause' | 'loop' | 'record';

export const transportLamps: CanonLamp[] = ['play', 'pause', 'loop'];

/** Milliseconds a lamp stays unlit when it blinks. */
export const lampBlinkMs = 120;
</script>

<script setup lang="ts">
import { computed, onBeforeUnmount, reactive, watch } from 'vue';
import { circleDot, pause, play, repeat } from '../lib/lucide.ts';
import CanonIcon from './canon-icon.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-lamps.css';

const props = defineProps<{
  /** Which lamps; every one is always present. Default play, pause, loop. */
  lamps?: readonly CanonLamp[];
  lit?: readonly CanonLamp[];
  /** A count per lamp; each change turns that lamp off for a split second. */
  flashes?: Partial<Record<CanonLamp, number>>;
}>();

const icons = { play, pause, loop: repeat, record: circleDot };
const list = computed(() =>
  props.lamps?.length ? props.lamps : transportLamps,
);

const blinking = reactive(new Set<CanonLamp>());
const timers = new Map<CanonLamp, number>();
let last = new Map<CanonLamp, number>();

watch(
  () => list.value.map((lamp) => [lamp, props.flashes?.[lamp] ?? 0] as const),
  (counts) => {
    const before = last;
    last = new Map(counts);
    for (const [lamp, count] of counts) {
      const previous = before.get(lamp);
      if (previous === undefined || previous === count) continue;
      window.clearTimeout(timers.get(lamp));
      blinking.add(lamp);
      timers.set(
        lamp,
        window.setTimeout(() => blinking.delete(lamp), lampBlinkMs),
      );
    }
  },
  { immediate: true },
);

onBeforeUnmount(() => timers.forEach((timer) => window.clearTimeout(timer)));
</script>

<!--
  Transport lamps: every icon is always present, lit while its state holds.
  Record lights red.
-->
<template>
  <span class="canon-lamps" aria-hidden="true">
    <span
      v-for="lamp in list"
      :key="lamp"
      class="canon-lamps-lamp"
      :class="[
        `canon-lamps-lamp--${lamp}`,
        {
          'canon-lamps-lamp--lit': lit?.includes(lamp),
          'canon-lamps-lamp--blink': blinking.has(lamp),
        },
      ]"
      ><CanonIcon :svg="icons[lamp]"
    /></span>
  </span>
</template>
