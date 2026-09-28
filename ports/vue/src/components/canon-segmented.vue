<script setup lang="ts">
import { computed, ref, type Component } from 'vue';
import CanonButton from './canon-button.vue';
import CanonGrid from './canon-grid.vue';
import '@canon/styles/tokens.css';

const props = defineProps<{
  /** Titles; with `icons`, what assistive technology reads. */
  items: string[];
  /** Cells that show a symbol instead of the title, one per item. */
  icons?: Component[];
  selected?: number;
  columns?: number;
  boxed?: boolean;
  disabled?: boolean;
  /** Indices of choices that cannot be taken now; they stay, greyed. */
  disabledIndices?: number[];
  onChange?: (index: number) => void;
}>();

// a pick holds until the selected prop changes
const picked = ref<{ index: number; over: number | undefined }>();

const selected = computed(() =>
  picked.value && picked.value.over === props.selected
    ? picked.value.index
    : (props.selected ?? 0),
);

const cells = computed(() =>
  props.items.map((title, index) => ({
    index,
    title,
    icon: props.icons?.[index],
    selected: index === selected.value,
    disabled:
      props.disabled || (props.disabledIndices?.includes(index) ?? false),
  })),
);

function pick(index: number) {
  if (index === selected.value) return;
  picked.value = { index, over: props.selected };
  props.onChange?.(index);
}
</script>

<!-- Single selection from a flush grid of cells. -->
<template>
  <CanonGrid
    class="canon-segmented"
    role="radiogroup"
    :columns="columns"
    :boxed="boxed"
  >
    <CanonButton
      v-for="cell in cells"
      :key="cell.index"
      role="radio"
      :aria-checked="cell.selected ? 'true' : 'false'"
      kind="segment"
      :text="cell.icon ? '' : cell.title"
      :icon="cell.icon"
      :label="cell.title"
      :selected="cell.selected"
      :disabled="cell.disabled"
      :on-click="() => pick(cell.index)"
    />
  </CanonGrid>
</template>
