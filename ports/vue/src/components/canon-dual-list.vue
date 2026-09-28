<script lang="ts">
export interface CanonDualItem {
  id: string;
  name: string;
  caption?: string;
}

type Side = 'left' | 'right';
</script>

<script setup lang="ts">
import { computed, ref, useId } from 'vue';
import CanonButton from './canon-button.vue';
import CanonGrid from './canon-grid.vue';
import CanonHeading from './canon-heading.vue';
import { vPress } from '../lib/press.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-dual-list.css';

const props = defineProps<{
  left: CanonDualItem[];
  right: CanonDualItem[];
  leftTitle: string;
  rightTitle: string;
  /** Height of each list in px; default 240. */
  listHeight?: number;
  onMoveRight?: (id: string) => void;
  onMoveLeft?: (id: string) => void;
  /** Item id and a delta of -1 or 1. */
  onReorder?: (id: string, delta: -1 | 1) => void;
}>();

const id = useId();
const picked = ref<{ side: Side; id: string }>();

/** The pick, while its item is still on that side. */
const selection = computed(() => {
  const pick = picked.value;
  if (!pick) return undefined;
  const items = pick.side === 'left' ? props.left : props.right;
  return items.some((item) => item.id === pick.id) ? pick : undefined;
});
const selectedSide = computed(() => selection.value?.side);
const rightIndex = computed(() => {
  const pick = selection.value;
  return pick?.side === 'right'
    ? props.right.findIndex((item) => item.id === pick.id)
    : -1;
});
const style = computed(() => ({
  '--canon-dual-list-height': `${props.listHeight ?? 240}px`,
}));

function rows(side: Side) {
  const items = side === 'left' ? props.left : props.right;
  return items.map((item) => ({
    item,
    side,
    selected: selection.value?.side === side && selection.value.id === item.id,
  }));
}
const columns = computed(() => [rows('left'), rows('right')]);

function select(side: Side, item: string) {
  picked.value = { side, id: item };
}

function move(side: Side) {
  const pick = selection.value;
  if (pick?.side !== side) return;
  picked.value = { side: side === 'left' ? 'right' : 'left', id: pick.id };
  (side === 'left' ? props.onMoveRight : props.onMoveLeft)?.(pick.id);
}

function reorder(delta: -1 | 1) {
  const pick = selection.value;
  if (pick?.side === 'right') props.onReorder?.(pick.id, delta);
}
</script>

<!-- Two columns with one selection between them; the right column can be reordered. -->
<template>
  <div class="canon-dual-list" :style="style">
    <div class="canon-dual-list-columns">
      <div
        v-for="(column, index) in columns"
        :key="index"
        class="canon-dual-list-column"
      >
        <CanonHeading
          :id="`${id}-${index}`"
          :text="index ? rightTitle : leftTitle"
        />
        <div
          class="canon-dual-list-items"
          role="group"
          :aria-labelledby="`${id}-${index}`"
        >
          <button
            v-for="row in column"
            :key="row.item.id"
            v-press
            type="button"
            class="canon-dual-list-item"
            :class="{ 'canon-dual-list-item--selected': row.selected }"
            :aria-pressed="row.selected ? 'true' : 'false'"
            @click="select(row.side, row.item.id)"
          >
            <span class="canon-dual-list-name">{{ row.item.name }}</span>
            <span v-if="row.item.caption" class="canon-dual-list-caption">{{
              row.item.caption
            }}</span>
          </button>
        </div>
      </div>
    </div>
    <CanonGrid>
      <CanonButton
        kind="cell"
        text="Show"
        :disabled="selectedSide !== 'left'"
        :on-click="() => move('left')"
      />
      <CanonButton
        kind="cell"
        text="Hide"
        :disabled="selectedSide !== 'right'"
        :on-click="() => move('right')"
      />
      <CanonButton
        kind="cell"
        text="Up"
        :disabled="rightIndex < 1"
        :on-click="() => reorder(-1)"
      />
      <CanonButton
        kind="cell"
        text="Down"
        :disabled="rightIndex < 0 || rightIndex >= right.length - 1"
        :on-click="() => reorder(1)"
      />
    </CanonGrid>
  </div>
</template>
