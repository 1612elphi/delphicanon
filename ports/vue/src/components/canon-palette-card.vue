<script lang="ts">
/** Width of the widened swatch against the others. */
export const widened = 3;
</script>

<script setup lang="ts">
import { computed, ref } from 'vue';
import {
  formatColour,
  hex,
  takesBlackInk,
  type ColourFormat,
  type Rgb,
} from '@canon/lib/colour.ts';
import { springEasing } from '@canon/lib/motion.ts';
import { toast } from '../lib/toast-store.ts';
import CanonGrid from './canon-grid.vue';
import CanonHeading from './canon-heading.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-palette-card.css';

const props = defineProps<{
  title: string;
  colours: Rgb[];
  /** Height of the swatches in px. */
  height?: number;
  selected?: number;
  onSelect?: (index: number | undefined) => void;
  /** Nearest colour name for a hex, shown on the widened swatch. */
  nameOf?: (hex: string) => string;
  /** The app's colour format settings; the widened swatch shows the first that is not hex. */
  primaryFormat?: ColourFormat;
  secondaryFormat?: ColourFormat;
}>();

defineSlots<{
  /** A choice between palettes, under the heading: a CanonSegmented. */
  picker?: () => unknown;
  /** Flush cells in a bar under the swatches: CanonButtons of kind cell. */
  actions?: () => unknown;
}>();

const spring = springEasing(0.82);

// a pick holds until the selected prop changes
const picked = ref<{ index: number; over: number | undefined }>();

const selected = computed(() => {
  const index =
    picked.value && picked.value.over === props.selected
      ? picked.value.index
      : props.selected;
  return index !== undefined && index < props.colours.length
    ? index
    : undefined;
});

const stripStyle = computed(() => ({
  blockSize: `${props.height ?? 156}px`,
  '--canon-palette-spring': spring,
}));

const detailFormat = computed<ColourFormat>(
  () =>
    [props.primaryFormat ?? 'hex', props.secondaryFormat ?? 'rgb'].find(
      (format) => format !== 'hex',
    ) ?? 'oklch',
);

const swatches = computed(() =>
  props.colours.map((colour, index) => {
    const code = hex(colour);
    const wide = index === selected.value;
    return {
      index,
      hex: code,
      wide,
      name: wide ? props.nameOf?.(code) : undefined,
      label: props.nameOf?.(code) ?? code,
      details: formatColour(colour, detailFormat.value),
      style: {
        background: code,
        color: takesBlackInk(colour) ? 'black' : 'white',
        flexGrow: wide ? widened : 1,
      },
    };
  }),
);

function tap(index: number) {
  if (index === selected.value) {
    void toast.copy(hex(props.colours[index]!));
    return;
  }
  picked.value = { index, over: props.selected };
  props.onSelect?.(index);
}
</script>

<!--
  A palette as swatches meeting at hairlines, under a heading. A tap widens
  a swatch to show its name and values; a tap on the widened swatch copies
  its hex.
-->
<template>
  <div class="canon-palette-card">
    <CanonHeading :text="title" />
    <slot name="picker" />
    <div class="canon-palette-card-strip" :style="stripStyle">
      <button
        v-for="swatch in swatches"
        :key="swatch.index"
        type="button"
        class="canon-palette-card-swatch"
        :class="{ 'canon-palette-card-swatch--wide': swatch.wide }"
        :style="swatch.style"
        :aria-label="swatch.label"
        :aria-pressed="swatch.wide ? 'true' : 'false'"
        @click="tap(swatch.index)"
      >
        <span class="canon-palette-card-name">{{ swatch.name }}</span>
        <span class="canon-palette-card-details">{{ swatch.details }}</span>
        <span class="canon-palette-card-hex">{{ swatch.hex }}</span>
      </button>
    </div>
    <CanonGrid v-if="$slots.actions"><slot name="actions" /></CanonGrid>
  </div>
</template>
