<script lang="ts">
import { canvasMetrics } from '@canon/lib/math/measure.ts';
import { Typesetter } from '@canon/lib/math/typeset.ts';

const accents = [
  'var(--canon-foreground)',
  'var(--canon-math-green)',
  'var(--canon-math-blue)',
  'var(--canon-math-clay)',
];
const names = ['Numbers', 'Functions', 'Calculus', 'Letters'];
export const lampHeight = 3;

function faces() {
  const setter = new Typesetter(canvasMetrics, 18);
  const functions = setter
    .text('f', { italic: true })
    .append(setter.parens(setter.text('x', { italic: true }), 0), 1);
  const calculus = setter.text('∫').append(setter.text('Σ'), 3);
  return [
    setter.text('123'),
    functions,
    calculus,
    setter.text('xyz', { italic: true }),
  ];
}
</script>

<script setup lang="ts">
import { computed } from 'vue';
import { vPress } from '../lib/press.ts';
import CanonMathView from './canon-math-view.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-tabs.css';

const props = defineProps<{
  /** The page position, fractional mid-swipe. */
  progress: number;
  onSelect?: (page: number) => void;
}>();

const tabFaces = faces();

const progress = computed(() =>
  Math.min(Math.max(props.progress, 0), names.length - 1),
);

const tabs = computed(() =>
  tabFaces.map((face, index) => {
    const near = Math.max(0, 1 - Math.abs(progress.value - index));
    return {
      face,
      index,
      name: names[index]!,
      selected: near > 0.5,
      style: `color: color-mix(in srgb, var(--canon-muted-foreground), ${accents[index]} ${Math.round(near * 100)}%)`,
    };
  }),
);

const lampStyle = computed(() => {
  const low = Math.floor(progress.value);
  const high = Math.min(low + 1, names.length - 1);
  const share = progress.value - low;
  // lamp narrows mid-swipe
  const width = 0.62 * (1 - 0.35 * Math.sin(Math.PI * share));
  return `--canon-math-progress: ${progress.value}; --canon-math-lamp: ${width}; background: color-mix(in srgb, ${accents[low]}, ${accents[high]} ${Math.round(share * 100)}%)`;
});
</script>

<!--
  The pages' names as maths, each lit in its page's colour as the page comes
  into view, over a lamp that slides and changes colour with the swipe.
-->
<template>
  <div class="canon-math-tabs">
    <button
      v-for="tab in tabs"
      :key="tab.index"
      v-press
      type="button"
      class="canon-math-tab"
      :aria-label="tab.name"
      :aria-current="tab.selected ? 'true' : undefined"
      :style="tab.style"
      @click="onSelect?.(tab.index)"
    >
      <CanonMathView :box="tab.face" :mono="true" aria-hidden="true" />
    </button>
    <span class="canon-math-tabs-lamp" :style="lampStyle"></span>
  </div>
</template>
