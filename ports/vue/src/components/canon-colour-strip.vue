<script setup lang="ts">
import { computed } from 'vue';
import {
  formatColour,
  hex,
  type ColourFormat,
  type Rgb,
} from '@canon/lib/colour.ts';
import { vPress } from '../lib/press.ts';
import { toast } from '../lib/toast-store.ts';
import CanonSwatch from './canon-swatch.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-colour-strip.css';

const props = defineProps<{
  colour: Rgb;
  /** Shows these colours as swatches instead, each copying its hex on a tap. */
  palette?: Rgb[];
  /** Nearest colour name for a hex. */
  nameOf?: (hex: string) => string;
  /** The value shown and copied; default hex. */
  format?: ColourFormat;
}>();

const value = computed(() => formatColour(props.colour, props.format ?? 'hex'));
const name = computed(() => props.nameOf?.(hex(props.colour)));
const showsPalette = computed(() => (props.palette?.length ?? 0) > 0);

const copy = () => void toast.copy(value.value);
</script>

<!--
  A strip along the bottom of a colour picture: swatch, nearest name, the
  colour in the primary format; a tap copies the value. Place it under the
  picture inside the same canvas.
-->
<template>
  <div class="canon-colour-strip">
    <div v-if="showsPalette" class="canon-colour-strip-palette">
      <CanonSwatch
        v-for="(swatch, i) in palette"
        :key="i"
        :colour="swatch"
        :name-of="nameOf"
      />
    </div>
    <button
      v-else
      v-press
      type="button"
      class="canon-colour-strip-single"
      :aria-label="`${name ?? ''} ${value}`"
      @click="copy"
    >
      <span
        class="canon-colour-strip-swatch"
        :style="{ background: hex(colour) }"
      ></span>
      <span class="canon-colour-strip-text">
        <span v-if="name" class="canon-colour-strip-name">{{ name }}</span>
        <span class="canon-colour-strip-value">{{ value }}</span>
      </span>
    </button>
  </div>
</template>
