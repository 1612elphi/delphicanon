<script lang="ts">
/** Seconds typing must pause before `onChange`. */
export const typingDelay = 0.4;
</script>

<script setup lang="ts">
import { h, onBeforeUnmount, ref, type FunctionalComponent } from 'vue';
import { clipboard, trash } from '../lib/lucide.ts';
import CanonButton from './canon-button.vue';
import CanonGrid from './canon-grid.vue';
import CanonIcon from './canon-icon.vue';
import CanonTextArea from './canon-text-area.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-text-input.css';

const props = defineProps<{
  /** Starting text; later changes to the prop are not followed. */
  value?: string;
  placeholder?: string;
  /** Height of the text area in px; default 128. */
  height?: number;
  /** Accessible name of the text area; default Input. */
  label?: string;
  /** Typing arrives once it pauses; Paste and Clear arrive at once. */
  onChange?: (text: string) => void;
}>();

const PasteIcon: FunctionalComponent = () => h(CanonIcon, { svg: clipboard });
const TrashIcon: FunctionalComponent = () => h(CanonIcon, { svg: trash });

const text = ref(props.value ?? '');
let timer: number | undefined;
let gone = false;

function typed(value: string) {
  text.value = value;
  window.clearTimeout(timer);
  timer = window.setTimeout(
    () => props.onChange?.(text.value),
    typingDelay * 1000,
  );
}

/** Text set from code reaches `onChange` at once. */
function setText(value: string) {
  window.clearTimeout(timer);
  text.value = value;
  props.onChange?.(value);
}

async function paste() {
  try {
    const value = await navigator.clipboard.readText();
    if (!gone) setText(value);
  } catch {
    return;
  }
}

const clear = () => setText('');

defineExpose({ setText });

onBeforeUnmount(() => {
  gone = true;
  window.clearTimeout(timer);
});
</script>

<!-- The input block of a text tool: a text area with Paste and Clear under it. -->
<template>
  <div class="canon-text-input">
    <CanonTextArea
      :value="text"
      :placeholder="placeholder || 'Type or paste'"
      :height="height || 128"
      :on-change="typed"
      :aria-label="label || 'Input'"
    />
    <CanonGrid>
      <CanonButton text="Paste" :icon="PasteIcon" :on-click="paste" />
      <CanonButton
        text="Clear"
        :icon="TrashIcon"
        :disabled="!text"
        :on-click="clear"
      />
    </CanonGrid>
  </div>
</template>
