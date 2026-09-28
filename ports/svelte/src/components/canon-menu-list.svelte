<script lang="ts" module>
  import type { Snippet } from 'svelte';
  import type {
    CanonMenuEntry as Entry,
    CanonMenuItem as Item,
  } from '@canon/lib/menu.ts';
  import { isOpen } from '@canon/lib/popover.ts';

  export type CanonMenuEntry = Entry<Snippet>;
  export type CanonMenuItem = Item<Snippet>;

  // opened by our own code, which places focus itself
  const claimed = new WeakSet<HTMLElement>();

  function ownItems(panel: HTMLElement): HTMLElement[] {
    return [...panel.children].filter(
      (child): child is HTMLElement =>
        child instanceof HTMLElement &&
        child.classList.contains('canon-menu-item'),
    );
  }

  /** Opens a CanonMenuList panel if it is closed and focuses its first or last item, or leaves focus where it is. */
  export function showMenu(
    panel: HTMLElement,
    focus: 'first' | 'last' | 'none',
  ) {
    if (!isOpen(panel)) {
      claimed.add(panel);
      panel.showPopover();
    }
    if (focus === 'none') return;
    const items = ownItems(panel);
    (focus === 'first' ? items[0] : items.at(-1))?.focus({
      preventScroll: true,
    });
  }
</script>

<script lang="ts">
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLAttributes } from 'svelte/elements';
  import CanonMenuList from './canon-menu-list.svelte';
  import CanonRule from './canon-rule.svelte';
  import { check, chevronRight, iconSnippet } from '../lib/control-icons.ts';
  import {
    isSeparator,
    menuRole,
    typeAhead,
    typeAheadMs,
    wrap,
    type CanonMenuRole,
  } from '@canon/lib/menu.ts';
  import { attach, focusLeaves, hide } from '@canon/lib/popover.ts';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-popover.css';

  interface Props extends Omit<
    HTMLAttributes<HTMLDivElement>,
    'children' | 'onselect'
  > {
    items: CanonMenuEntry[];
    onSelect: (item: CanonMenuItem) => void;
    /** Arrow keys past the inline edge: 1 towards the end, -1 towards the start. A menu bar moves to its neighbour. */
    onEdge?: (step: 1 | -1) => void;
    /** A submenu: the inline start arrow closes it, and its items open no further menus. */
    sub?: boolean;
  }

  interface Row {
    index: number;
    item?: CanonMenuItem;
    role?: CanonMenuRole;
    checked?: string;
    sub?: CanonMenuEntry[];
    subId?: string;
  }

  let {
    items,
    onSelect,
    onEdge,
    sub: isSub,
    class: className,
    ...rest
  }: Props = $props();

  const Check = iconSnippet(check);
  const ChevronRight = iconSnippet(chevronRight);

  const uid = $props.id();
  const id = `${uid}-list`;
  let panel: HTMLElement | undefined;
  let typed = '';
  let typedAt = -Infinity;

  const rows = $derived(
    items.map((entry, index): Row => {
      if (isSeparator(entry)) return { index };
      const sub = !isSub && entry.items?.length ? entry.items : undefined;
      const checkable = entry.kind === 'checkbox' || entry.kind === 'radio';
      return {
        index,
        item: entry,
        role: menuRole(entry),
        checked: checkable ? String(entry.checked === true) : undefined,
        sub,
        subId: sub ? `${id}-${index}` : undefined,
      };
    }),
  );

  /** A column for checks or icons when any item has one, so titles line up. */
  const checks = $derived(
    items.some((entry) => entry.kind === 'checkbox' || entry.kind === 'radio'),
  );
  const icons = $derived(
    items.some((entry) => !isSeparator(entry) && entry.icon !== undefined),
  );

  const setup: Attachment<HTMLElement> = (element) => {
    panel = element;
    const toggle = (event: ToggleEvent) => {
      if (event.newState !== 'open' || claimed.delete(element)) return;
      if (!element.contains(document.activeElement))
        ownItems(element)[0]?.focus({ preventScroll: true });
    };
    element.addEventListener('toggle', toggle);
    element.addEventListener('keydown', keydown);
    element.addEventListener('focusout', focusout);
    return () => {
      element.removeEventListener('toggle', toggle);
      element.removeEventListener('keydown', keydown);
      element.removeEventListener('focusout', focusout);
    };
  };

  // one attachment per index, so a new items array does not re-anchor an open submenu
  const submenus: Attachment<HTMLElement>[] = [];
  function submenu(index: number): Attachment<HTMLElement> {
    let attachment = submenus[index];
    if (!attachment) {
      attachment = (sub) => {
        const item = sub.parentElement?.querySelector<HTMLElement>(
          `:scope > [data-index="${index}"]`,
        );
        if (!item) return;
        return attach(sub, item, {
          placement: 'right-start',
          invokes: true,
          gap: '0px',
        });
      };
      submenus[index] = attachment;
    }
    return attachment;
  }

  function subPanel(row: Row): HTMLElement | undefined {
    return row.subId
      ? (panel?.querySelector<HTMLElement>(`#${row.subId}`) ?? undefined)
      : undefined;
  }

  function select(item: CanonMenuItem) {
    if (!isSub && panel) hide(panel);
    onSelect(item);
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
    if (event.pointerType === 'touch' || !panel) return;
    (event.currentTarget as HTMLElement).focus({ preventScroll: true });
    for (const open of panel.querySelectorAll<HTMLElement>(
      ':scope > .canon-menu:popover-open',
    ))
      if (open.id !== row.subId) open.hidePopover();
    const sub = subPanel(row);
    if (sub && !row.item?.disabled) showMenu(sub, 'none');
  }

  function keydown(event: KeyboardEvent) {
    const element = event.currentTarget as HTMLElement;
    const target = event.target as HTMLElement;
    if (target.parentElement !== element) return;
    const own = ownItems(element);
    const at = own.indexOf(target);
    const row = rows[Number(target.dataset['index'])];
    const go = (index: number) => own[index]?.focus({ preventScroll: true });
    const rtl = element.matches(':dir(rtl)');
    const toEnd = rtl ? 'ArrowLeft' : 'ArrowRight';
    const toStart = rtl ? 'ArrowRight' : 'ArrowLeft';
    switch (event.key) {
      case 'ArrowDown':
        go(wrap(at, 1, own.length));
        break;
      case 'ArrowUp':
        go(wrap(at, -1, own.length));
        break;
      case 'Home':
        go(0);
        break;
      case 'End':
        go(own.length - 1);
        break;
      case toEnd: {
        const sub = row && subPanel(row);
        if (sub && !row?.item?.disabled) showMenu(sub, 'first');
        else onEdge?.(1);
        break;
      }
      case toStart:
        if (isSub) hide(element);
        else onEdge?.(-1);
        break;
      default:
        if (!searchTitles(event, own, at)) return;
    }
    event.preventDefault();
  }

  function searchTitles(
    event: KeyboardEvent,
    own: HTMLElement[],
    at: number,
  ): boolean {
    const { key } = event;
    if (key.length !== 1 || key === ' ') return false;
    if (event.ctrlKey || event.metaKey || event.altKey) return false;
    typed = event.timeStamp - typedAt < typeAheadMs ? typed + key : key;
    typedAt = event.timeStamp;
    const titles = own.map(
      (element) => rows[Number(element.dataset['index'])]?.item?.title ?? '',
    );
    const found = typeAhead(titles, typed, at);
    if (found >= 0) own[found]!.focus({ preventScroll: true });
    return true;
  }

  function focusout(event: FocusEvent) {
    if (isSub) return;
    const element = event.currentTarget as HTMLElement;
    if (focusLeaves(element, event)) hide(element);
  }
</script>

<!--
  @component
  The popover panel of a menu (role menu) that CanonMenu, CanonContextMenu
  and CanonMenuBar open. The owner anchors it with `attach` and opens it
  with its trigger or `showMenu`, and imports `canon-menu.css`.
-->
<div
  {id}
  class={[
    'canon-popover',
    'canon-menu',
    checks && 'canon-menu--checks',
    icons && 'canon-menu--icons',
    className,
  ]}
  popover="auto"
  role="menu"
  {@attach setup}
  {...rest}
>
  {#each rows as row (row.index)}
    {#if row.item}
      <button
        type="button"
        class={[
          'canon-menu-item',
          row.item.destructive && 'canon-menu-item--destructive',
        ]}
        role={row.role}
        tabindex="-1"
        data-index={row.index}
        aria-checked={row.checked as 'true' | 'false' | undefined}
        aria-disabled={row.item.disabled ? 'true' : undefined}
        aria-haspopup={row.sub ? 'menu' : undefined}
        onclick={(event) => activate(row, event)}
        onpointerenter={(event) => hover(row, event)}
      >
        <span class="canon-menu-item-check" aria-hidden="true">
          {#if row.item.checked}{@render Check()}{/if}
        </span>
        <span class="canon-menu-item-icon" aria-hidden="true">
          {#if row.item.icon}{@render row.item.icon()}{/if}
        </span>
        <span class="canon-menu-item-title">{row.item.title}</span>
        {#if row.item.shortcut}
          <kbd class="canon-menu-item-shortcut">{row.item.shortcut}</kbd>
        {/if}
        {#if row.sub}
          <span class="canon-menu-item-more" aria-hidden="true">
            {@render ChevronRight()}
          </span>
        {/if}
      </button>
      {#if row.sub}
        <CanonMenuList
          id={row.subId}
          items={row.sub}
          sub
          onSelect={select}
          {onEdge}
          {@attach submenu(row.index)}
        />
      {/if}
    {:else}
      <CanonRule />
    {/if}
  {/each}
</div>
