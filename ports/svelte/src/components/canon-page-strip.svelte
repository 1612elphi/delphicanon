<script lang="ts" module>
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
</script>

<script lang="ts">
  import { onDestroy } from 'svelte';
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLAttributes } from 'svelte/elements';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-page-strip.css';

  interface Props extends HTMLAttributes<HTMLDivElement> {
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
  }

  let {
    pages,
    reorders,
    onMove,
    onDrop,
    dropTypes = ['image/*'],
    menu,
    onSelect,
    selected,
    empty,
    class: className,
    ...rest
  }: Props = $props();

  const sheetOffset = 4;
  const longPressMs = 500;
  const dragType = 'application/x-canon-page';

  let dropAt = $state<number>();
  let menuItems = $state<CanonPageMenuItem[]>([]);
  let menuElement = $state<HTMLElement>();
  let dragFrom: number | undefined;
  let pressTimer: number | undefined;

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

  function wholeRect(page: CanonPage): PageRect {
    return { x: 0, y: 0, width: page.size.width, height: page.size.height };
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

  const cells = $derived.by(() => {
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
      return {
        page,
        index,
        number: index + 1,
        lit: index === selected,
        paperStyle: paperStyle(page),
        sheets: sheets(Math.min(page.depth ?? 0, 3)),
        clip: `clip-path: inset(${pct(area.top)} ${pct(area.right)} ${pct(area.bottom)} ${pct(area.left)})`,
        pictureStyle: picture.join('; '),
        dashed: isWhole(page.area, page)
          ? undefined
          : `inset: ${pct(area.top)} ${pct(area.right)} ${pct(area.bottom)} ${pct(area.left)}`,
        label: page.name
          ? `Page ${index + 1}, ${page.name}`
          : `Page ${index + 1}`,
        dropBefore: dropAt === index,
        dropAfter: dropAt === count && index === count - 1,
      };
    });
  });

  // keyboard reordering
  function onKey(index: number, event: KeyboardEvent) {
    if (!reorders || !event.altKey) return;
    const list = (event.currentTarget as HTMLElement).closest('ol');
    const rtl = list && getComputedStyle(list).direction === 'rtl';
    const forward = rtl ? 'ArrowLeft' : 'ArrowRight';
    const back = rtl ? 'ArrowRight' : 'ArrowLeft';
    const to =
      event.key === forward ? index + 1 : event.key === back ? index - 1 : NaN;
    if (Number.isNaN(to)) return;
    event.preventDefault();
    if (to < 0 || to >= pages.length) return;
    onMove?.(index, to);
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
    if (!reorders || !event.dataTransfer) {
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
    dropAt = undefined;
  }

  function accepts(event: DragEvent) {
    const transfer = event.dataTransfer;
    if (!reorders || !transfer) return false;
    if (dragFrom !== undefined) return true;
    if (!transfer.types.includes('Files')) return false;
    const types = [...transfer.items]
      .filter((item) => item.kind === 'file')
      .map((item) => item.type);
    return types.length === 0 || types.some((t) => matches(t, dropTypes));
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
    if (at !== dropAt) dropAt = at;
  }

  function onDragLeave(event: DragEvent) {
    const list = event.currentTarget as HTMLElement;
    if (!list.contains(event.relatedTarget as Node | null)) dropAt = undefined;
  }

  function onDropFiles(event: DragEvent) {
    if (!accepts(event)) return;
    event.preventDefault();
    const at = destination(event.currentTarget as HTMLElement, event.clientX);
    const from = dragFrom;
    onDragEnd();
    if (from !== undefined) {
      const to = Math.min(at > from ? at - 1 : at, pages.length - 1);
      if (to !== from) onMove?.(from, to);
      return;
    }
    const files = [...(event.dataTransfer?.files ?? [])].filter((file) =>
      matches(file.type, dropTypes),
    );
    if (files.length > 0) onDrop?.(at, files);
  }

  function openMenu(index: number, x: number, y: number) {
    const items = menu?.(index);
    const element = menuElement;
    if (!items?.length || !element) return false;
    menuItems = items;
    element.style.left = `${x}px`;
    element.style.top = `${y}px`;
    element.showPopover();
    requestAnimationFrame(() =>
      element.querySelector<HTMLElement>('[role=menuitem]')?.focus(),
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

  function cancelPress() {
    clearTimeout(pressTimer);
  }

  const longPress: Attachment<HTMLElement> = (button) => {
    const start = (event: PointerEvent) => {
      if (event.pointerType !== 'touch' || !menu) return;
      const { clientX: x, clientY: y } = event;
      const index = Number(
        button.closest<HTMLElement>('[data-page-index]')?.dataset['pageIndex'],
      );
      cancelPress();
      pressTimer = window.setTimeout(() => openMenu(index, x, y), longPressMs);
    };
    const ends = ['pointerup', 'pointercancel', 'pointerleave'] as const;
    button.addEventListener('pointerdown', start);
    ends.forEach((type) => button.addEventListener(type, cancelPress));
    return () => {
      cancelPress();
      button.removeEventListener('pointerdown', start);
      ends.forEach((type) => button.removeEventListener(type, cancelPress));
    };
  };

  function choose(item: CanonPageMenuItem) {
    menuElement?.hidePopover();
    item.action();
  }

  onDestroy(cancelPress);
</script>

<!--
  @component
  Pages to scale in a sideways row, numbered, with an optional name under
  each: drag to reorder, drop files in, a long-press menu, a tap that lights
  a page, and sheets stacked behind a page that stands for several.
-->
<div class={['canon-page-strip', className]} {...rest}>
  {#if pages.length}
    <ol
      class="canon-page-strip-list"
      ondragover={onDragOver}
      ondragleave={onDragLeave}
      ondrop={onDropFiles}
    >
      {#each cells as cell (cell.index)}
        <li
          class={[
            'canon-page-strip-cell',
            cell.lit && 'canon-page-strip-cell--lit',
            cell.dropBefore && 'canon-page-strip-cell--drop-before',
            cell.dropAfter && 'canon-page-strip-cell--drop-after',
          ]}
          style={cell.paperStyle}
          data-page-index={cell.index}
          draggable={reorders ? 'true' : undefined}
          ondragstart={(event) => onDragStart(cell.index, event)}
          ondragend={onDragEnd}
        >
          <button
            type="button"
            class="canon-page-strip-page"
            aria-label={cell.label}
            aria-current={cell.lit ? 'true' : undefined}
            aria-haspopup={menu ? 'menu' : undefined}
            aria-keyshortcuts={reorders
              ? 'Alt+ArrowLeft Alt+ArrowRight'
              : undefined}
            onclick={() => onSelect?.(cell.index)}
            onkeydown={(event) => onKey(cell.index, event)}
            oncontextmenu={(event) => onContextMenu(cell.index, event)}
            {@attach longPress}
          >
            <span class="canon-page-strip-art">
              <span class="canon-page-strip-stack">
                {#each cell.sheets as sheet, i (i)}
                  <span class="canon-page-strip-sheet" style={sheet}></span>
                {/each}
                <span class="canon-page-strip-paper">
                  {#if cell.page.picture}
                    <span class="canon-page-strip-clip" style={cell.clip}>
                      <img
                        class="canon-page-strip-picture"
                        src={cell.page.picture}
                        alt=""
                        draggable="false"
                        style={cell.pictureStyle}
                      />
                    </span>
                  {/if}
                  {#if cell.dashed}
                    <span class="canon-page-strip-area" style={cell.dashed}
                    ></span>
                  {/if}
                </span>
              </span>
            </span>
            <span
              class={[
                'canon-page-strip-number',
                cell.page.name && 'canon-page-strip-number--named',
              ]}>{cell.number}</span
            >
            {#if cell.page.name}
              <span class="canon-page-strip-name">{cell.page.name}</span>
            {/if}
          </button>
        </li>
      {/each}
    </ol>
  {:else}
    <p class="canon-page-strip-empty">{empty || 'Pages'}</p>
  {/if}
  <div
    class="canon-page-strip-menu"
    popover="auto"
    role="menu"
    bind:this={menuElement}
  >
    {#each menuItems as item, i (i)}
      <button
        type="button"
        role="menuitem"
        class={[
          'canon-page-strip-menu-item',
          item.destructive && 'canon-page-strip-menu-item--destructive',
        ]}
        onclick={() => choose(item)}>{item.title}</button
      >
    {/each}
  </div>
</div>
