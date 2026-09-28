<script lang="ts">
import { isOpen } from '@canon/lib/popover.ts';

// opened by our own code, which places focus itself
const claimed = new WeakSet<HTMLElement>();

function ownItems(panel: HTMLElement): HTMLElement[] {
  return [...panel.children].filter(
    (child): child is HTMLElement =>
      child instanceof HTMLElement &&
      child.classList.contains('canon-menu-item'),
  );
}

/** Opens a CanonMenu panel if it is closed and focuses its first or last item, or leaves focus where it is. */
export function showMenu(panel: HTMLElement, focus: 'first' | 'last' | 'none') {
  if (!isOpen(panel)) {
    claimed.add(panel);
    panel.showPopover();
  }
  if (focus === 'none') return;
  const items = ownItems(panel);
  (focus === 'first' ? items[0] : items.at(-1))?.focus({ preventScroll: true });
}
</script>

<script setup lang="ts">
import {
  computed,
  h,
  onBeforeUnmount,
  onMounted,
  shallowRef,
  useId,
  useTemplateRef,
  watch,
  type Component,
  type FunctionalComponent,
} from 'vue';
import {
  isSeparator,
  menuRole,
  typeAhead,
  typeAheadMs,
  wrap,
  type CanonMenuEntry as Entry,
  type CanonMenuItem as Item,
  type CanonMenuRole,
} from '@canon/lib/menu.ts';
import { attach, hide, type CanonPlacement } from '@canon/lib/popover.ts';
import { check, chevronRight } from '../lib/lucide.ts';
import { elementOf, type CanonTriggerRef } from '../lib/trigger.ts';
import CanonIcon from './canon-icon.vue';
import CanonRule from './canon-rule.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-popover.css';
import '@canon/components/canon-menu.css';

export type CanonMenuEntry = Entry<Component>;
export type CanonMenuItem = Item<Component>;

defineOptions({ inheritAttrs: false });

const props = defineProps<{
  items: CanonMenuEntry[];
  /** Default bottom-start. */
  placement?: CanonPlacement;
  onSelect?: (item: CanonMenuItem) => void;
  /** Arrow keys past the inline edge: 1 towards the end, -1 towards the start. A menu bar moves to its neighbour. */
  onEdge?: (step: 1 | -1) => void;
  /** A submenu: the inline start arrow closes it, and its items open no further menus. */
  sub?: boolean;
}>();

defineSlots<{
  /** Bind `trigger` as the ref of the button that opens the menu. */
  default?: (props: { trigger: CanonTriggerRef }) => unknown;
}>();

interface Row {
  index: number;
  item?: CanonMenuItem;
  role?: CanonMenuRole;
  checked?: 'true' | 'false';
  sub?: CanonMenuEntry[];
  subId?: string;
}

const Check: FunctionalComponent = () => h(CanonIcon, { svg: check });
const ChevronRight: FunctionalComponent = () =>
  h(CanonIcon, { svg: chevronRight });

const id = `${useId()}-menu`;
const panelRef = useTemplateRef<HTMLElement>('panel');
const anchor = shallowRef<HTMLElement | null>(null);
let typed = '';
let typedAt = -Infinity;

const rows = computed<Row[]>(() =>
  props.items.map((entry, index) => {
    if (isSeparator(entry)) return { index };
    const sub = !props.sub && entry.items?.length ? entry.items : undefined;
    const checkable = entry.kind === 'checkbox' || entry.kind === 'radio';
    return {
      index,
      item: entry,
      role: menuRole(entry),
      checked: checkable
        ? entry.checked === true
          ? 'true'
          : 'false'
        : undefined,
      sub,
      subId: sub ? `${id}-${index}` : undefined,
    };
  }),
);

/** A column for checks or icons when any item has one, so titles line up. */
const checks = computed(() =>
  props.items.some(
    (entry) => entry.kind === 'checkbox' || entry.kind === 'radio',
  ),
);
const icons = computed(() =>
  props.items.some((entry) => !isSeparator(entry) && entry.icon !== undefined),
);

const trigger: CanonTriggerRef = (target) => {
  anchor.value = elementOf(target);
};

watch(
  [anchor, panelRef, () => props.placement],
  ([button, panel, placement], _, onCleanup) => {
    if (!button || !panel) return;
    const detach = attach(panel, button, {
      placement: placement ?? 'bottom-start',
      invokes: true,
    });
    button.setAttribute('aria-haspopup', 'menu');
    const keydown = (event: KeyboardEvent) => {
      if (event.key !== 'ArrowDown' && event.key !== 'ArrowUp') return;
      event.preventDefault();
      showMenu(panel, event.key === 'ArrowDown' ? 'first' : 'last');
    };
    button.addEventListener('keydown', keydown);
    onCleanup(() => {
      button.removeEventListener('keydown', keydown);
      button.removeAttribute('aria-haspopup');
      detach();
    });
  },
  { flush: 'post' },
);

// each submenu anchors to the item before it
const subIds = computed(() =>
  rows.value
    .filter((row) => row.subId)
    .map((row) => `${row.index}:${row.subId}`)
    .join(' '),
);
let detachSubs: (() => void)[] = [];

function anchorSubs() {
  detachSubs.forEach((detach) => detach());
  detachSubs = [];
  const panel = panelRef.value;
  if (!panel) return;
  for (const row of rows.value) {
    const sub = subPanel(row);
    const item = panel.querySelector<HTMLElement>(
      `:scope > [data-index="${row.index}"]`,
    );
    if (sub && item)
      detachSubs.push(
        attach(sub, item, {
          placement: 'right-start',
          invokes: true,
          gap: '0px',
        }),
      );
  }
}

onMounted(anchorSubs);
watch(subIds, anchorSubs, { flush: 'post' });
onBeforeUnmount(() => detachSubs.forEach((detach) => detach()));

function subPanel(row: Row): HTMLElement | undefined {
  return row.subId
    ? (panelRef.value?.querySelector<HTMLElement>(`#${row.subId}`) ?? undefined)
    : undefined;
}

function select(item: CanonMenuItem) {
  if (!props.sub && panelRef.value) hide(panelRef.value);
  props.onSelect?.(item);
}

function activate(row: Row, event: MouseEvent) {
  if (row.sub) {
    // the item is the submenu's popovertarget; a second click must not close it
    event.preventDefault();
    const sub = subPanel(row);
    if (sub && !row.item?.disabled) showMenu(sub, 'first');
    return;
  }
  if (row.item && !row.item.disabled) select(row.item);
}

function hover(row: Row, event: PointerEvent) {
  const panel = panelRef.value;
  if (event.pointerType === 'touch' || !panel) return;
  (event.currentTarget as HTMLElement).focus({ preventScroll: true });
  for (const open of panel.querySelectorAll<HTMLElement>(
    ':scope > .canon-menu:popover-open',
  ))
    if (open.id !== row.subId) open.hidePopover();
  const sub = subPanel(row);
  if (sub && !row.item?.disabled) showMenu(sub, 'none');
}

function toggled(event: Event) {
  const panel = event.currentTarget as HTMLElement;
  if ((event as ToggleEvent).newState !== 'open' || claimed.delete(panel))
    return;
  if (!panel.contains(document.activeElement))
    ownItems(panel)[0]?.focus({ preventScroll: true });
}

function keydown(event: KeyboardEvent) {
  const panel = event.currentTarget as HTMLElement;
  const target = event.target as HTMLElement;
  if (target.parentElement !== panel) return;
  const items = ownItems(panel);
  const at = items.indexOf(target);
  const row = rows.value[Number(target.dataset['index'])];
  const go = (index: number) => items[index]?.focus({ preventScroll: true });
  const rtl = panel.matches(':dir(rtl)');
  const toEnd = rtl ? 'ArrowLeft' : 'ArrowRight';
  const toStart = rtl ? 'ArrowRight' : 'ArrowLeft';
  switch (event.key) {
    case 'ArrowDown':
      go(wrap(at, 1, items.length));
      break;
    case 'ArrowUp':
      go(wrap(at, -1, items.length));
      break;
    case 'Home':
      go(0);
      break;
    case 'End':
      go(items.length - 1);
      break;
    case toEnd: {
      const sub = row && subPanel(row);
      if (sub && !row?.item?.disabled) showMenu(sub, 'first');
      else props.onEdge?.(1);
      break;
    }
    case toStart:
      if (props.sub) hide(panel);
      else props.onEdge?.(-1);
      break;
    default:
      if (!findTyped(event, items, at)) return;
  }
  event.preventDefault();
}

function findTyped(
  event: KeyboardEvent,
  items: HTMLElement[],
  at: number,
): boolean {
  const { key } = event;
  if (key.length !== 1 || key === ' ') return false;
  if (event.ctrlKey || event.metaKey || event.altKey) return false;
  typed = event.timeStamp - typedAt < typeAheadMs ? typed + key : key;
  typedAt = event.timeStamp;
  const titles = items.map(
    (element) =>
      rows.value[Number(element.dataset['index'])]?.item?.title ?? '',
  );
  const found = typeAhead(titles, typed, at);
  if (found >= 0) items[found]!.focus({ preventScroll: true });
  return true;
}

function focusout(event: FocusEvent) {
  if (props.sub) return;
  const panel = event.currentTarget as HTMLElement;
  const next = event.relatedTarget;
  if (next instanceof Node && !panel.contains(next)) hide(panel);
}
</script>

<!--
  A dropdown menu opened by the consumer's button: a click, Enter or Space
  opens it at the first item, the down and up arrows at the first and last.
  Choosing an item closes it and reports the item. Without the default
  slot it is the bare panel (Ember's CanonMenuList) that CanonContextMenu
  and CanonMenuBar anchor and open with showMenu.
-->
<template>
  <slot :trigger="trigger" />
  <div
    :id="id"
    ref="panel"
    class="canon-popover canon-menu"
    :class="{ 'canon-menu--checks': checks, 'canon-menu--icons': icons }"
    popover="auto"
    role="menu"
    v-bind="$attrs"
    @toggle="toggled"
    @keydown="keydown"
    @focusout="focusout"
  >
    <template v-for="row in rows" :key="row.index">
      <template v-if="row.item">
        <button
          type="button"
          class="canon-menu-item"
          :class="{ 'canon-menu-item--destructive': row.item.destructive }"
          :role="row.role"
          tabindex="-1"
          :data-index="row.index"
          :aria-checked="row.checked"
          :aria-disabled="row.item.disabled ? 'true' : undefined"
          :aria-haspopup="row.sub ? 'menu' : undefined"
          @click="activate(row, $event)"
          @pointerenter="hover(row, $event)"
        >
          <span class="canon-menu-item-check" aria-hidden="true">
            <Check v-if="row.item.checked" />
          </span>
          <span class="canon-menu-item-icon" aria-hidden="true">
            <component :is="row.item.icon" v-if="row.item.icon" />
          </span>
          <span class="canon-menu-item-title">{{ row.item.title }}</span>
          <kbd v-if="row.item.shortcut" class="canon-menu-item-shortcut">{{
            row.item.shortcut
          }}</kbd>
          <span v-if="row.sub" class="canon-menu-item-more" aria-hidden="true">
            <ChevronRight />
          </span>
        </button>
        <CanonMenu
          v-if="row.sub"
          :id="row.subId"
          :items="row.sub"
          :sub="true"
          :on-select="select"
          :on-edge="onEdge"
        />
      </template>
      <CanonRule v-else />
    </template>
  </div>
</template>
