<script lang="ts">
export type CanonLoaderMode = 'snake' | 'comet' | 'dot' | 'twin' | 'thinking';
</script>

<script setup lang="ts">
import { computed } from 'vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-loader.css';

const props = defineProps<{
  /** Default snake. thinking swings back and forth. */
  mode?: CanonLoaderMode;
  /** Runs anticlockwise; thinking ignores it. */
  reverse?: boolean;
  /** Cell side in px; default 8. */
  cell?: number;
  /** Gap between cells in px; default 2. */
  gap?: number;
}>();

const style = computed(() => ({
  '--canon-loader-cell': `${props.cell ?? 8}px`,
  '--canon-loader-gap': `${props.gap ?? 2}px`,
}));
</script>

<!--
  3 x 3 cell loader in the current colour, the web nds-loader: a lit head
  runs clockwise round the eight outer cells over a lit centre.
-->
<template>
  <div
    class="canon-loader"
    :class="[
      `canon-loader--${mode ? mode : 'snake'}`,
      { 'canon-loader--reverse': reverse },
    ]"
    role="status"
    aria-label="Loading"
    :style="style"
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
</template>
