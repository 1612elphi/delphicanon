<script setup lang="ts">
import { onBeforeUnmount, onMounted, useTemplateRef } from 'vue';
import { afterPress, attach, isOpen } from '@canon/lib/popover.ts';
import CanonMenu, {
  showMenu,
  type CanonMenuEntry,
  type CanonMenuItem,
} from './canon-menu.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-context-menu.css';

const props = defineProps<{
  items: CanonMenuEntry[];
  onSelect?: (item: CanonMenuItem) => void;
}>();

defineSlots<{
  /** The area the menu belongs to. */
  default?: () => unknown;
}>();

const pointRef = useTemplateRef<HTMLElement>('point');
let returnTo: Element | null = null;
let detach: (() => void) | undefined;

function menuPanel() {
  return pointRef.value?.nextElementSibling as HTMLElement | null | undefined;
}

onMounted(() => {
  const point = pointRef.value!;
  detach = attach(menuPanel()!, point, {
    placement: 'bottom-start',
    gap: '0px',
    returnFocus: () => returnTo,
  });
});
onBeforeUnmount(() => detach?.());

// client coordinates are physical, so left and top
function openAt(x: number, y: number) {
  const point = pointRef.value;
  const panel = menuPanel();
  if (!point || !panel) return;
  returnTo = document.activeElement;
  point.style.left = `${x}px`;
  point.style.top = `${y}px`;
  showMenu(panel, 'first');
}

function below(element: Element) {
  const box = element.getBoundingClientRect();
  openAt(element.matches(':dir(rtl)') ? box.right : box.left, box.bottom);
}

function contextmenu(event: MouseEvent) {
  event.preventDefault();
  const panel = menuPanel();
  // the key already opened it, or the click is on the menu itself
  if (!panel || isOpen(panel)) return;
  // a context menu key the keydown did not see reports no position
  if (event.clientX === 0 && event.clientY === 0)
    below(event.target as Element);
  else {
    const { clientX, clientY } = event;
    afterPress(event.buttons !== 0, () => openAt(clientX, clientY));
  }
}

function keydown(event: KeyboardEvent) {
  const key =
    event.key === 'ContextMenu' || (event.shiftKey && event.key === 'F10');
  if (!key || menuPanel()?.contains(event.target as Node)) return;
  event.preventDefault();
  below(event.target as Element);
}

function select(item: CanonMenuItem) {
  props.onSelect?.(item);
}
</script>

<!--
  A menu opened at the pointer by a secondary click in the area, or below
  the focused element by Shift+F10 or the context menu key. Focus goes
  back to where it was when the menu closes.
-->
<template>
  <div class="canon-context-menu" @contextmenu="contextmenu" @keydown="keydown">
    <slot />
    <span ref="point" class="canon-context-menu-point" aria-hidden="true" />
    <CanonMenu :items="items" :on-select="select" />
  </div>
</template>
