<script lang="ts">
// iOS: insets 24, symbol padding 6, slack 8
const titleRoom = 38;
let measure: CanvasRenderingContext2D | null | undefined;

function titleFits(button: HTMLElement): boolean {
  const title = button.querySelector<HTMLElement>('.canon-button-title');
  measure ??= document.createElement('canvas').getContext('2d');
  if (!title || !measure) return true;
  measure.font = getComputedStyle(title).font;
  const iconWidth =
    parseFloat(
      getComputedStyle(button).getPropertyValue('--canon-icon-inline'),
    ) || 0;
  return (
    measure.measureText(title.textContent ?? '').width +
      iconWidth +
      titleRoom <=
    button.clientWidth
  );
}
</script>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, useTemplateRef, watch } from 'vue';
import { balanced, spans } from '@canon/lib/grid.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-grid.css';

const props = defineProps<{
  /** Cells per row at most; default all in one row. */
  columns?: number;
  /** Draws the outer hairline; leave off inside CanonRows or a CanonRow. */
  boxed?: boolean;
}>();

const grid = useTemplateRef<HTMLElement>('grid');
let stop: (() => void) | undefined;

function place() {
  const element = grid.value;
  if (!element) return;
  // a popover or menu panel renders beside its trigger and is no cell
  const cells = [...element.children].filter(
    (child) => !child.hasAttribute('popover'),
  ) as HTMLElement[];
  const columns = props.columns ?? cells.length;
  const perRow = spans(cells.length, columns);
  const widest = balanced(cells.length, columns)[0] ?? 1;
  element.style.setProperty('--canon-grid-columns', String(widest));
  cells.forEach((cell, i) => {
    const span = perRow[i] ?? 1;
    cell.style.gridColumn = span > 1 ? `span ${span}` : '';
  });
  fit();
}

// titles drop together
function fit() {
  const element = grid.value;
  if (!element) return;
  const tight = [...element.children].some(
    (cell) =>
      cell instanceof HTMLElement &&
      cell.matches('[data-canon-fit]') &&
      !titleFits(cell),
  );
  element.toggleAttribute('data-symbol-only', tight);
}

onMounted(() => {
  const element = grid.value!;
  place();
  const children = new MutationObserver(place);
  children.observe(element, { childList: true });
  const titles = new MutationObserver(fit);
  titles.observe(element, { characterData: true, subtree: true });
  const size = new ResizeObserver(fit);
  size.observe(element);
  void document.fonts?.ready.then(fit);
  stop = () => {
    children.disconnect();
    titles.disconnect();
    size.disconnect();
  };
});
watch(() => props.columns, place, { flush: 'post' });
onBeforeUnmount(() => stop?.());
</script>

<!--
  Equal cells divided by hairlines. Rows are balanced, so four cells at
  three columns give two rows of two; the last cell of a short row spans the
  rest. Filling buttons with a symbol all show the symbol alone when any
  one title does not fit.
-->
<template>
  <div ref="grid" class="canon-grid" :class="{ 'canon-grid--boxed': boxed }">
    <slot />
  </div>
</template>
