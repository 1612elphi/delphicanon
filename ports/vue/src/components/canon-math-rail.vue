<script lang="ts">
import { h, type FunctionalComponent } from 'vue';
import type { Key } from '@canon/lib/math/expression.ts';

export const railHeights = { regular: 44, short: 38 };
/** Sideways drag, in px, per caret place. */
export const stride = 16;
export const arrowWidth = 50;

const chevron =
  (d: string): FunctionalComponent =>
  () =>
    h(
      'svg',
      {
        viewBox: '0 0 24 24',
        fill: 'none',
        stroke: 'currentColor',
        'stroke-width': '2',
        'stroke-linecap': 'round',
        'stroke-linejoin': 'round',
      },
      [h('path', { d })],
    );

const arrows: { key: Key; label: string; icon: FunctionalComponent }[] = [
  { key: { kind: 'left' }, label: 'Left', icon: chevron('m15 18-6-6 6-6') },
  { key: { kind: 'up' }, label: 'Up', icon: chevron('m18 15-6-6-6 6') },
  { key: { kind: 'down' }, label: 'Down', icon: chevron('m6 9 6 6 6-6') },
  { key: { kind: 'right' }, label: 'Right', icon: chevron('m9 18 6-6-6-6') },
];
</script>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, useTemplateRef } from 'vue';
import CanonButton from './canon-button.vue';
import { capture } from '@canon/lib/math/draw.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-rail.css';

const props = defineProps<{
  /** Moves the caret; false when it could not move. */
  onStep?: (key: Key) => boolean;
  short?: boolean;
}>();

const phase = ref(0);

const style = computed(
  () =>
    `--canon-math-rail-height: ${props.short ? railHeights.short : railHeights.regular}px; --canon-math-arrow-width: ${arrowWidth}px`,
);

const step = (key: Key) => props.onStep?.(key) ?? false;

const ribs = useTemplateRef<HTMLElement>('ribs');
let stop: (() => void) | undefined;

onMounted(() => {
  const element = ribs.value!;
  let last = 0;
  let stepped = 0;
  let start: number | undefined;
  const down = (event: PointerEvent) => {
    if (event.button !== 0) return;
    event.stopPropagation();
    capture(element, event.pointerId);
    start = event.clientX;
    last = 0;
    stepped = 0;
  };
  const move = (event: PointerEvent) => {
    if (start === undefined) return;
    const x = event.clientX - start;
    phase.value += x - last;
    last = x;
    while (x - stepped > stride) {
      stepped += stride;
      step({ kind: 'right' });
    }
    while (x - stepped < -stride) {
      stepped -= stride;
      step({ kind: 'left' });
    }
  };
  const up = () => (start = undefined);
  element.addEventListener('pointerdown', down);
  element.addEventListener('pointermove', move);
  element.addEventListener('pointerup', up);
  element.addEventListener('pointercancel', up);
  stop = () => {
    element.removeEventListener('pointerdown', down);
    element.removeEventListener('pointermove', move);
    element.removeEventListener('pointerup', up);
    element.removeEventListener('pointercancel', up);
  };
});
onBeforeUnmount(() => stop?.());
</script>

<!--
  The caret's controls, under the expression: ribs that slide with a
  sideways drag, one caret place per stride, then the four arrow keys.
-->
<template>
  <div class="canon-math-rail" :style="style">
    <div
      ref="ribs"
      class="canon-math-rail-ribs"
      :style="`--canon-math-rail-phase: ${phase}px`"
      aria-hidden="true"
    ></div>
    <CanonButton
      v-for="arrow in arrows"
      :key="arrow.label"
      kind="cell"
      :icon="arrow.icon"
      :label="arrow.label"
      :repeats="true"
      :on-click="() => step(arrow.key)"
    />
  </div>
</template>
