<script lang="ts">
export type CanonLoupePixels =
  ImageData | ImageBitmap | HTMLCanvasElement | HTMLImageElement;

/** 31 px across when no pixels are given, as on iOS. */
const defaultCount = 31;
</script>

<script setup lang="ts">
import { computed, useTemplateRef, watch } from 'vue';
import { hex, takesBlackInk, type Rgb } from '@canon/lib/colour.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-loupe.css';

const props = defineProps<{
  /** The pixels around the sample point, one canvas pixel each, the sample in the middle. */
  pixels?: CanonLoupePixels;
  /** The sampled colour: the frame, and the ground behind missing pixels. */
  colour: Rgb;
}>();

const style = computed(() => ({
  '--canon-loupe-colour': hex(props.colour),
  '--canon-loupe-ink': takesBlackInk(props.colour)
    ? 'var(--canon-loupe-ink-dark)'
    : 'var(--canon-loupe-ink-light)',
  '--canon-loupe-count': props.pixels?.width || defaultCount,
}));

const canvas = useTemplateRef<HTMLCanvasElement>('canvas');
watch(
  [canvas, () => props.pixels],
  ([element, pixels]) => {
    const context = element?.getContext('2d');
    if (!element || !context) return;
    if (!pixels) {
      context.clearRect(0, 0, element.width, element.height);
      return;
    }
    element.width = pixels.width;
    element.height = pixels.height;
    if (pixels instanceof ImageData) context.putImageData(pixels, 0, 0);
    else context.drawImage(pixels, 0, 0);
  },
  { flush: 'post' },
);
</script>

<!--
  The pixels around a sample point, magnified without smoothing, framed in
  the sampled colour. Place it with `frame` from `lib/loupe.ts`; it takes
  no pointer input.
-->
<template>
  <div class="canon-loupe" :style="style" aria-hidden="true">
    <canvas ref="canvas" class="canon-loupe-pixels"></canvas>
    <div class="canon-loupe-centre"></div>
  </div>
</template>
