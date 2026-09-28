<script setup lang="ts">
import { computed, ref, useTemplateRef, watch } from 'vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-canvas.css';

const props = defineProps<{
  /** Fixed height of the band in px, rules included. */
  height?: number;
  /** Width over height of the content; used when `height` is not set. */
  aspect?: number;
  /** Caps the band's height in a wide column; the content letterboxes itself. */
  maxHeight?: number;
  /** never: always an edge-to-edge band. unlessWide: a band beside a sidebar, a framed box everywhere else. */
  boxing?: 'never' | 'unlessWide';
  /** CSS colour behind the content; default the card colour. */
  background?: string;
  /** Tiles `--canon-pattern` faintly under the content. A CanonSplit banner always has it. */
  pattern?: boolean;
  /**
   * Takes the band's height from the content's own height at the column's
   * width, plus the rules; content with no height hides the band.
   */
  fitting?: boolean;
  /** With `fitting`: a change of the content's height at the same width animates the band. */
  animated?: boolean;
}>();

const fitted = ref<number>();
const eases = ref(false);
const collapsed = computed(() => props.fitting && fitted.value === 0);

const style = computed(() => {
  const { height, aspect, maxHeight, background } = props;
  return {
    '--canon-canvas-natural':
      height !== undefined
        ? `${height}px`
        : `calc(100cqw / ${aspect ?? 1} + 2 * var(--canon-frame))`,
    '--canon-canvas-fitted':
      props.fitting && fitted.value !== undefined
        ? `${fitted.value}px`
        : undefined,
    '--canon-canvas-max':
      maxHeight !== undefined ? `${maxHeight}px` : undefined,
    '--canon-canvas-background': background || undefined,
  };
});

const fit = useTemplateRef<HTMLElement>('fit');
watch(
  fit,
  (element, _, onCleanup) => {
    if (!element) return;
    let width: number | undefined;
    const observer = new ResizeObserver(([entry]) => {
      const box = entry?.borderBoxSize[0];
      if (!box) return;
      eases.value = Boolean(props.animated) && box.inlineSize === width;
      width = box.inlineSize;
      fitted.value = box.blockSize;
    });
    observer.observe(element);
    onCleanup(() => observer.disconnect());
  },
  { flush: 'post' },
);
</script>

<!--
  Edge-to-edge band for a picture, a preview or a drawing surface, ruled
  above and below. As a page section it spans its column; as a CanonSplit
  banner it spans every column. Place it between blocks of CanonRows.
-->
<template>
  <div
    class="canon-canvas"
    :class="{
      'canon-canvas--unless-wide': boxing === 'unlessWide',
      'canon-canvas--pattern': pattern,
      'canon-canvas--fitting': fitting,
      'canon-canvas--collapsed': collapsed,
      'canon-canvas--eases': eases,
    }"
    :style="style"
    :data-canon-height="height"
    :data-canon-aspect="aspect"
  >
    <div class="canon-canvas-content">
      <div v-if="fitting" ref="fit" class="canon-canvas-fit"><slot /></div>
      <slot v-else />
    </div>
  </div>
</template>
