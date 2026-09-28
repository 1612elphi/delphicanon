<script setup lang="ts">
import { computed, ref, useTemplateRef } from 'vue';
import CanonButton from './canon-button.vue';
import { splitForMiddle } from '@canon/lib/files.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-file-cell.css';

const props = defineProps<{
  /** As the file input's accept attribute; empty takes any file. */
  accept?: string;
  labelledBy?: string;
  disabled?: boolean;
  onChange?: (file: File) => void;
}>();

// ponytail: no clear(); re-render the cell to empty it
const file = ref<File>();
const parts = computed(() =>
  file.value ? splitForMiddle(file.value.name) : undefined,
);

const input = useTemplateRef<HTMLInputElement>('input');

function choose() {
  input.value?.click();
}

function picked(event: Event) {
  const element = event.target as HTMLInputElement;
  const chosen = element.files?.[0];
  element.value = '';
  if (!chosen) return;
  file.value = chosen;
  props.onChange?.(chosen);
}
</script>

<!-- File name beside a Choose cell. -->
<template>
  <div class="canon-file-cell" role="group" :aria-labelledby="labelledBy">
    <span
      class="canon-file-cell-name"
      :class="{ 'canon-file-cell-name--none': !parts }"
    >
      <template v-if="parts">
        <span class="canon-file-cell-head">{{ parts[0] }}</span>
        <span class="canon-file-cell-tail">{{ parts[1] }}</span>
      </template>
      <template v-else>None</template>
    </span>
    <CanonButton
      kind="cell"
      text="Choose"
      :disabled="disabled"
      :on-click="choose"
    />
    <input
      ref="input"
      type="file"
      class="canon-file-cell-input"
      :accept="accept"
      hidden
      @change="picked"
    />
  </div>
</template>
