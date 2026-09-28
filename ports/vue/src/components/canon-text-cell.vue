<script setup lang="ts">
import '@canon/styles/tokens.css';
import '@canon/components/canon-text-cell.css';

const props = defineProps<{
  value?: string;
  placeholder?: string;
  /** Called on every edit. */
  onChange?: (value: string) => void;
}>();

function edited(event: Event) {
  props.onChange?.((event.target as HTMLInputElement).value);
}

function blurOnEnter(event: KeyboardEvent) {
  if (event.key === 'Enter') (event.target as HTMLInputElement).blur();
}
</script>

<!-- Text field that meets its row's edges. -->
<template>
  <input
    type="text"
    class="canon-text-cell"
    :value="value"
    :placeholder="placeholder"
    enterkeyhint="done"
    @input="edited"
    @keydown="blurOnEnter"
  />
</template>
