<script lang="ts">
/** Typed text is read after this pause, on Return, and when the field loses focus. */
export const typingPauseMs = 400;

interface EyeDropperResult {
  sRGBHex: string;
}

type EyeDropperWindow = Window & {
  EyeDropper?: new () => { open(): Promise<EyeDropperResult> };
};
</script>

<script setup lang="ts">
import { computed, onBeforeUnmount, ref } from 'vue';
import { hex, parseColour, parseHex, type Rgb } from '@canon/lib/colour.ts';
import { Pipette } from '../lib/control-icons.ts';
import CanonButton from './canon-button.vue';
import CanonRule from './canon-rule.vue';
import CanonTextCell from './canon-text-cell.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-colour-notation-input.css';

const props = defineProps<{
  /** Shown as hex while the field is not being typed in. */
  colour?: Rgb;
  /** A formatted value shown instead of `colour`'s hex. */
  text?: string;
  /** A picked colour, and a typed one read by the default `parse`. */
  onColour?: (colour: Rgb) => void;
  /**
   * Reads typed text and uses it; false turns the text red. The default
   * reads any notation `parseColour` knows and passes it to `onColour`.
   */
  parse?: (text: string) => boolean;
  placeholder?: string;
  /** Id of the element that names the field, such as a row title. */
  labelledBy?: string;
  label?: string;
}>();

// the typed text holds until what is shown changes
const typed = ref<{ text: string; over: string }>();
const fails = ref(false);
let typing: number | undefined;
let focused = false;
const hasEyedropper = 'EyeDropper' in window;

const shown = computed(
  () => props.text ?? (props.colour ? hex(props.colour) : ''),
);
const value = computed(() =>
  typed.value && (focused || typed.value.over === shown.value)
    ? typed.value.text
    : shown.value,
);
const failing = computed(
  () => fails.value && value.value === typed.value?.text,
);

function parseText(text: string): boolean {
  if (props.parse) return props.parse(text);
  const colour = parseColour(text);
  if (colour) props.onColour?.(colour);
  return colour !== undefined;
}

function read() {
  window.clearTimeout(typing);
  const text = typed.value?.text;
  if (text === undefined) return;
  fails.value = !parseText(text) && text.trim() !== '';
}

function type(text: string) {
  typed.value = { text, over: shown.value };
  fails.value = false;
  window.clearTimeout(typing);
  typing = window.setTimeout(read, typingPauseMs);
}

function focus() {
  focused = true;
}

function leave() {
  focused = false;
  read();
  if (typed.value) typed.value = { ...typed.value, over: shown.value };
}

async function pick() {
  const { EyeDropper } = window as EyeDropperWindow;
  if (!EyeDropper) return;
  try {
    const { sRGBHex } = await new EyeDropper().open();
    const colour = parseHex(sRGBHex);
    if (colour) props.onColour?.(colour);
  } catch {
    // Escape closes the eyedropper with an AbortError
  }
}

onBeforeUnmount(() => window.clearTimeout(typing));
</script>

<!--
  A colour typed in any notation beside an eyedropper cell. The eyedropper
  is the browser's EyeDropper and is left out where the browser has none.
-->
<template>
  <div class="canon-colour-notation-input">
    <CanonTextCell
      class="canon-colour-notation-input-field"
      :class="{ 'canon-colour-notation-input--fails': failing }"
      :value="value"
      :placeholder="placeholder ? placeholder : 'oklch(0.64 0.15 264)'"
      :on-change="type"
      spellcheck="false"
      autocomplete="off"
      autocapitalize="off"
      :aria-labelledby="labelledBy"
      :aria-label="label"
      :aria-invalid="failing ? 'true' : undefined"
      @focus="focus"
      @blur="leave"
    />
    <template v-if="hasEyedropper">
      <CanonRule :vertical="true" />
      <CanonButton
        kind="cell"
        :icon="Pipette"
        label="Colour"
        :on-click="pick"
      />
    </template>
  </div>
</template>
