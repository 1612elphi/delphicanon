<script lang="ts">
export interface CanonTile {
  label: string;
  value: string;
  /** Share of a level bar along the tile's bottom edge, 0 to 1; none draws no bar. */
  level?: number;
}

/** Least width of a tile; the grid never goes below two columns. */
export const tileWidth = 168;
</script>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, useTemplateRef } from 'vue';
import CanonBar from './canon-bar.vue';
import CanonGrid from './canon-grid.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-tiles.css';

defineProps<{ items: CanonTile[] }>();

const columns = ref(2);
const root = useTemplateRef<HTMLElement>('root');
let stop: (() => void) | undefined;

onMounted(() => {
  let frame = 0;
  // a new column count changes the height; set it next frame, outside this observation
  const observer = new ResizeObserver(([entry]) => {
    const width = entry?.contentRect.width ?? 0;
    const count = Math.max(2, Math.floor(width / tileWidth));
    cancelAnimationFrame(frame);
    if (count !== columns.value)
      frame = requestAnimationFrame(() => (columns.value = count));
  });
  observer.observe(root.value!);
  stop = () => {
    cancelAnimationFrame(frame);
    observer.disconnect();
  };
});
onBeforeUnmount(() => stop?.());
</script>

<!--
  Read-only values as a hairline grid of tiles, label over value. As many
  columns as fit; a short last row stretches its last tile.
-->
<template>
  <div ref="root" class="canon-tiles">
    <CanonGrid :columns="columns">
      <div v-for="(item, i) in items" :key="i" class="canon-tiles-tile">
        <span class="canon-tiles-label">{{ item.label }}</span>
        <span class="canon-tiles-value">{{ item.value }}</span>
        <CanonBar
          v-if="item.level !== undefined"
          class="canon-tiles-level"
          :share="item.level"
        />
      </div>
    </CanonGrid>
  </div>
</template>
