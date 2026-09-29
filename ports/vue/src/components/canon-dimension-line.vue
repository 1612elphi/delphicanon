<script setup lang="ts">
import CanonFigure from './canon-figure.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-dimension-line.css';

defineProps<{
  pixels: number;
  /** Turned a quarter, reading upwards, beside the leading side of what it measures. */
  down?: boolean;
  /** Muted rule and ticks, no figure: an empty picture keeps a loaded one's frame without stale sizes. */
  blank?: boolean;
}>();
</script>

<!--
  A measured span: a rule with end ticks along its bottom edge, the pixel
  figure centred above it. Placed by the consumer with inset and size
  properties (`dimensionLines` in `lib/dimension-line.ts`), before the turn.
-->
<template>
  <span
    class="canon-dimension-line"
    :class="{
      'canon-dimension-line--down': down,
      'canon-dimension-line--blank': blank,
    }"
    aria-hidden="true"
  >
    <CanonFigure
      v-if="!blank"
      class="canon-dimension-line-figure"
      :text="String(pixels)"
      unit="px"
      :size="17"
      halo="var(--canon-muted)"
    />
  </span>
</template>
