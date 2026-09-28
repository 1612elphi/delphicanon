<script lang="ts">
/** A rectangle in PDF points, origin at the bottom left. */
export interface PageRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface CanonPage {
  /** PDF points. */
  size: { width: number; height: number };
  /** The part of the page in use, dashed when it is not the whole page; default the whole page. */
  area?: PageRect;
  /** Where the picture is drawn, clipped to `area`; default the whole page. */
  placement?: PageRect;
  /** URL of the picture. */
  picture?: string;
  name?: string;
  /** Sheets stacked behind, up to three, for a page that stands for several. */
  depth?: number;
  /** Clockwise degrees in quarter turns, the picture only. */
  turn?: number;
}

export interface CanonPageMenuItem {
  title: string;
  action: () => void;
  destructive?: boolean;
}

/** Height of a canvas holding the strip. */
export const pageStripHeight = 196;
const sheetOffset = 4;
const longPressMs = 500;
const dragType = 'application/x-canon-page';

// farthest sheet first, so the nearer ones paint over it
function sheets(depth: number) {
  return Array.from({ length: depth }, (_, k) => {
    const step = (depth - k) * sheetOffset;
    return `translate: ${step}px ${-step}px`;
  });
}

function pct(value: number) {
  return `${Math.round(value * 10000) / 100}%`;
}

function paperStyle(page: CanonPage) {
  const { width, height } = page.size;
  const ratio = Math.max(width, 1) / Math.max(height, 1);
  const room = Math.min(page.depth ?? 0, 3) * sheetOffset;
  return `--canon-page-ratio: ${ratio}; --canon-page-room: ${room}px`;
}

/** Top, right, bottom, left of a PDF rect as shares of the page, top-left origin. */
function inset(rect: PageRect, page: CanonPage) {
  const { width, height } = page.size;
  return {
    top: (height - rect.y - rect.height) / height,
    left: rect.x / width,
    right: (width - rect.x - rect.width) / width,
    bottom: rect.y / height,
  };
}

function isWhole(rect: PageRect | undefined, page: CanonPage) {
  return (
    !rect ||
    (rect.x === 0 &&
      rect.y === 0 &&
      rect.width === page.size.width &&
      rect.height === page.size.height)
  );
}

function matches(type: string, patterns: string[]) {
  return patterns.some((pattern) =>
    pattern.endsWith('/*')
      ? type.startsWith(pattern.slice(0, -1))
      : type === pattern,
  );
}

function wholeRect(page: CanonPage): PageRect {
  return { x: 0, y: 0, width: page.size.width, height: page.size.height };
}
</script>

<script setup lang="ts">
import { computed, onBeforeUnmount, ref, useTemplateRef } from 'vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-page-strip.css';

const props = defineProps<{
  pages: CanonPage[];
  /** Pages drag to new places, by pointer or Alt and the arrow keys; files drop in. */
  reorders?: boolean;
  /** A page moved; the consumer moves it in `pages`. */
  onMove?: (from: number, to: number) => void;
  /** Files dropped in before `index`, already filtered by `dropTypes`. */
  onDrop?: (index: number, files: File[]) => void;
  /** MIME types taken from outside, `image/*` style; default images. */
  dropTypes?: string[];
  /** Items of the menu a long press or a secondary click opens on a page. */
  menu?: (index: number) => CanonPageMenuItem[] | undefined;
  onSelect?: (index: number) => void;
  /** The lit page. */
  selected?: number;
  /** Shown when there are no pages; default Pages. */
  empty?: string;
}>();

const dropAt = ref<number>();
const menuItems = ref<CanonPageMenuItem[]>([]);
const menuElement = useTemplateRef<HTMLElement>('menuElement');
let dragFrom: number | undefined;
let press: number | undefined;

const dropTypes = computed(() => props.dropTypes ?? ['image/*']);

const cells = computed(() => {
  const { pages, selected } = props;
  const count = pages.length;
  return pages.map((page, index) => {
    const area = inset(page.area ?? wholeRect(page), page);
    const placement = inset(page.placement ?? wholeRect(page), page);
    const quarter = ((((page.turn ?? 0) / 90) % 4) + 4) % 4;
    const w = page.size.width;
    const h = page.size.height;
    const placed = page.placement ?? wholeRect(page);
    const sideways = quarter % 2 === 1;
    const picture = [
      `left: ${pct(placement.left + placed.width / w / 2)}`,
      `top: ${pct(placement.top + placed.height / h / 2)}`,
      `width: ${pct((sideways ? placed.height : placed.width) / w)}`,
      `height: ${pct((sideways ? placed.width : placed.height) / h)}`,
      `transform: translate(-50%, -50%) rotate(${quarter * 90}deg)`,
    ];
    const edges = `${pct(area.top)} ${pct(area.right)} ${pct(area.bottom)} ${pct(area.left)}`;
    return {
      page,
      index,
      number: index + 1,
      lit: index === selected,
      paperStyle: paperStyle(page),
      sheets: sheets(Math.min(page.depth ?? 0, 3)),
      clip: `clip-path: inset(${edges})`,
      pictureStyle: picture.join('; '),
      dashed: isWhole(page.area, page) ? undefined : `inset: ${edges}`,
      label: page.name
        ? `Page ${index + 1}, ${page.name}`
        : `Page ${index + 1}`,
      dropBefore: dropAt.value === index,
      dropAfter: dropAt.value === count && index === count - 1,
    };
  });
});

const select = (index: number) => props.onSelect?.(index);

// keyboard reordering
function onKey(index: number, event: KeyboardEvent) {
  if (!props.reorders || !event.altKey) return;
  const list = (event.currentTarget as HTMLElement).closest('ol');
  const rtl = list && getComputedStyle(list).direction === 'rtl';
  const forward = rtl ? 'ArrowLeft' : 'ArrowRight';
  const back = rtl ? 'ArrowRight' : 'ArrowLeft';
  const to =
    event.key === forward ? index + 1 : event.key === back ? index - 1 : NaN;
  if (Number.isNaN(to)) return;
  event.preventDefault();
  if (to < 0 || to >= props.pages.length) return;
  props.onMove?.(index, to);
  requestAnimationFrame(() =>
    list
      ?.querySelector<HTMLElement>(
        `[data-page-index="${to}"] .canon-page-strip-page`,
      )
      ?.focus(),
  );
}

function onDragStart(index: number, event: DragEvent) {
  cancelPress();
  if (!props.reorders || !event.dataTransfer) {
    event.preventDefault();
    return;
  }
  dragFrom = index;
  event.dataTransfer.effectAllowed = 'move';
  event.dataTransfer.setData(dragType, String(index));
  const paper = (event.currentTarget as HTMLElement).querySelector(
    '.canon-page-strip-paper',
  );
  if (paper) event.dataTransfer.setDragImage(paper, 0, 0);
}

function onDragEnd() {
  dragFrom = undefined;
  dropAt.value = undefined;
}

function accepts(event: DragEvent) {
  const transfer = event.dataTransfer;
  if (!props.reorders || !transfer) return false;
  if (dragFrom !== undefined) return true;
  if (!transfer.types.includes('Files')) return false;
  const types = [...transfer.items]
    .filter((item) => item.kind === 'file')
    .map((item) => item.type);
  return types.length === 0 || types.some((t) => matches(t, dropTypes.value));
}

function destination(list: HTMLElement, x: number) {
  const rtl = getComputedStyle(list).direction === 'rtl';
  const items = [...list.querySelectorAll<HTMLElement>('[data-page-index]')];
  const index = items.findIndex((item) => {
    const box = item.getBoundingClientRect();
    const middle = box.left + box.width / 2;
    return rtl ? x > middle : x < middle;
  });
  return index === -1 ? items.length : index;
}

function onDragOver(event: DragEvent) {
  if (!accepts(event)) return;
  event.preventDefault();
  event.dataTransfer!.dropEffect = dragFrom !== undefined ? 'move' : 'copy';
  const at = destination(event.currentTarget as HTMLElement, event.clientX);
  if (at !== dropAt.value) dropAt.value = at;
}

function onDragLeave(event: DragEvent) {
  const list = event.currentTarget as HTMLElement;
  if (!list.contains(event.relatedTarget as Node | null))
    dropAt.value = undefined;
}

function onDropFiles(event: DragEvent) {
  if (!accepts(event)) return;
  event.preventDefault();
  const at = destination(event.currentTarget as HTMLElement, event.clientX);
  const from = dragFrom;
  onDragEnd();
  if (from !== undefined) {
    const to = Math.min(at > from ? at - 1 : at, props.pages.length - 1);
    if (to !== from) props.onMove?.(from, to);
    return;
  }
  const files = [...(event.dataTransfer?.files ?? [])].filter((file) =>
    matches(file.type, dropTypes.value),
  );
  if (files.length > 0) props.onDrop?.(at, files);
}

function openMenu(index: number, x: number, y: number) {
  const items = props.menu?.(index);
  const menu = menuElement.value;
  if (!items?.length || !menu) return false;
  menuItems.value = items;
  menu.style.left = `${x}px`;
  menu.style.top = `${y}px`;
  menu.showPopover();
  requestAnimationFrame(() =>
    menu.querySelector<HTMLElement>('[role=menuitem]')?.focus(),
  );
  return true;
}

function onContextMenu(index: number, event: MouseEvent) {
  let { clientX: x, clientY: y } = event;
  // the context menu key reports no position
  if (x === 0 && y === 0) {
    const box = (event.currentTarget as HTMLElement).getBoundingClientRect();
    x = box.left;
    y = box.bottom;
  }
  if (openMenu(index, x, y)) event.preventDefault();
}

function startPress(index: number, event: PointerEvent) {
  if (event.pointerType !== 'touch' || !props.menu) return;
  const { clientX: x, clientY: y } = event;
  cancelPress();
  press = window.setTimeout(() => openMenu(index, x, y), longPressMs);
}

function cancelPress() {
  window.clearTimeout(press);
}

function choose(item: CanonPageMenuItem) {
  menuElement.value?.hidePopover();
  item.action();
}

onBeforeUnmount(cancelPress);
</script>

<!--
  Pages to scale in a sideways row, numbered, with an optional name under
  each: drag to reorder, drop files in, a long-press menu, a tap that lights
  a page, and sheets stacked behind a page that stands for several.
-->
<template>
  <div class="canon-page-strip">
    <ol
      v-if="pages.length"
      class="canon-page-strip-list"
      @dragover="onDragOver"
      @dragleave="onDragLeave"
      @drop="onDropFiles"
    >
      <li
        v-for="cell in cells"
        :key="cell.index"
        class="canon-page-strip-cell"
        :class="{
          'canon-page-strip-cell--lit': cell.lit,
          'canon-page-strip-cell--drop-before': cell.dropBefore,
          'canon-page-strip-cell--drop-after': cell.dropAfter,
        }"
        :style="cell.paperStyle"
        :data-page-index="cell.index"
        :draggable="reorders ? 'true' : undefined"
        @dragstart="onDragStart(cell.index, $event)"
        @dragend="onDragEnd"
      >
        <button
          type="button"
          class="canon-page-strip-page"
          :aria-label="cell.label"
          :aria-current="cell.lit ? 'true' : undefined"
          :aria-haspopup="menu ? 'menu' : undefined"
          :aria-keyshortcuts="
            reorders ? 'Alt+ArrowLeft Alt+ArrowRight' : undefined
          "
          @click="select(cell.index)"
          @keydown="onKey(cell.index, $event)"
          @contextmenu="onContextMenu(cell.index, $event)"
          @pointerdown="startPress(cell.index, $event)"
          @pointerup="cancelPress"
          @pointercancel="cancelPress"
          @pointerleave="cancelPress"
        >
          <span class="canon-page-strip-art">
            <span class="canon-page-strip-stack">
              <span
                v-for="(sheet, k) in cell.sheets"
                :key="k"
                class="canon-page-strip-sheet"
                :style="sheet"
              ></span>
              <span class="canon-page-strip-paper">
                <span
                  v-if="cell.page.picture"
                  class="canon-page-strip-clip"
                  :style="cell.clip"
                >
                  <img
                    class="canon-page-strip-picture"
                    :src="cell.page.picture"
                    alt=""
                    draggable="false"
                    :style="cell.pictureStyle"
                  />
                </span>
                <span
                  v-if="cell.dashed"
                  class="canon-page-strip-area"
                  :style="cell.dashed"
                ></span>
              </span>
            </span>
          </span>
          <span
            class="canon-page-strip-number"
            :class="{ 'canon-page-strip-number--named': cell.page.name }"
            >{{ cell.number }}</span
          >
          <span v-if="cell.page.name" class="canon-page-strip-name">{{
            cell.page.name
          }}</span>
        </button>
      </li>
    </ol>
    <p v-else class="canon-page-strip-empty">{{ empty || 'Pages' }}</p>
    <div
      ref="menuElement"
      class="canon-page-strip-menu"
      popover="auto"
      role="menu"
    >
      <button
        v-for="(item, i) in menuItems"
        :key="i"
        type="button"
        role="menuitem"
        class="canon-page-strip-menu-item"
        :class="{
          'canon-page-strip-menu-item--destructive': item.destructive,
        }"
        @click="choose(item)"
      >
        {{ item.title }}
      </button>
    </div>
  </div>
</template>
