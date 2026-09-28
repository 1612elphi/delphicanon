<script setup lang="ts">
import { computed } from 'vue';
import {
  formatColour,
  hex,
  parseHex,
  type ColourFormat,
  type Rgb,
} from '@canon/lib/colour.ts';
import { vPress } from '../lib/press.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-colour-well.css';

const props = defineProps<{
  /** Caption over the hex, and the swatch's accessible name. */
  label?: string;
  colour: Rgb;
  /** The app's primary colour format, echoed under the hex unless it is hex. */
  format?: ColourFormat;
  onChange?: (colour: Rgb) => void;
}>();

const code = computed(() => hex(props.colour));
const digits = computed(() => code.value.slice(1));
const echo = computed(() =>
  props.format && props.format !== 'hex'
    ? formatColour(props.colour, props.format)
    : undefined,
);

function picked(event: Event) {
  const colour = parseHex((event.target as HTMLInputElement).value);
  if (colour) props.onChange?.(colour);
}

function typed(event: Event) {
  const field = event.target as HTMLInputElement;
  const entered = field.value.replace(/[^\da-f]/gi, '');
  const colour = entered.length === 6 ? parseHex(entered) : undefined;
  if (colour && hex(colour) !== code.value) props.onChange?.(colour);
  field.value = colour ? hex(colour).slice(1) : digits.value;
}

function done(event: KeyboardEvent) {
  if (event.key === 'Enter') (event.target as HTMLInputElement).blur();
}
</script>

<!-- Swatch cell that opens the system picker, beside a hex field. -->
<template>
  <div class="canon-colour-well">
    <div v-press class="canon-colour-well-swatch" :style="{ background: code }">
      <input
        type="color"
        :value="code"
        :aria-label="label ? label : 'Colour'"
        @input="picked"
      />
    </div>
    <div class="canon-colour-well-cell">
      <span v-if="label" class="canon-colour-well-label">{{ label }}</span>
      <span class="canon-colour-well-field">
        <span class="canon-colour-well-hash" aria-hidden="true">#</span>
        <input
          type="text"
          :value="digits"
          placeholder="000000"
          maxlength="7"
          spellcheck="false"
          autocomplete="off"
          autocapitalize="off"
          :aria-label="label ? label : 'Hex'"
          @change="typed"
          @keydown="done"
        />
      </span>
      <span v-if="echo" class="canon-colour-well-echo">{{ echo }}</span>
    </div>
  </div>
</template>
