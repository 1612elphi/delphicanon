import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import '../styles/tokens.css';
import './canon-page-strip.css';

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

export interface CanonPageStripSignature {
  Args: {
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
  };
  Element: HTMLDivElement;
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
    return htmlSafe(`translate: ${step}px ${-step}px`);
  });
}

function pct(value: number) {
  return `${Math.round(value * 10000) / 100}%`;
}

function paperStyle(page: CanonPage) {
  const { width, height } = page.size;
  const ratio = Math.max(width, 1) / Math.max(height, 1);
  const room = Math.min(page.depth ?? 0, 3) * sheetOffset;
  return htmlSafe(`--canon-page-ratio: ${ratio}; --canon-page-room: ${room}px`);
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

const register = modifier(
  (element: HTMLElement, [callback]: [(element: HTMLElement) => void]) => {
    callback(element);
  },
);

/**
 * Pages to scale in a sideways row, numbered, with an optional name under
 * each: drag to reorder, drop files in, a long-press menu, a tap that lights
 * a page, and sheets stacked behind a page that stands for several.
 */
export default class CanonPageStrip extends Component<CanonPageStripSignature> {
  @tracked dropAt?: number;
  @tracked menuItems: CanonPageMenuItem[] = [];
  #dragFrom?: number;
  #press?: number;
  #menu?: HTMLElement;

  get dropTypes() {
    return this.args.dropTypes ?? ['image/*'];
  }

  get cells() {
    const { pages, selected } = this.args;
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
        clip: htmlSafe(
          `clip-path: inset(${pct(area.top)} ${pct(area.right)} ${pct(area.bottom)} ${pct(area.left)})`,
        ),
        pictureStyle: htmlSafe(picture.join('; ')),
        dashed: isWhole(page.area, page)
          ? undefined
          : htmlSafe(
              `inset: ${pct(area.top)} ${pct(area.right)} ${pct(area.bottom)} ${pct(area.left)}`,
            ),
        label: page.name
          ? `Page ${index + 1}, ${page.name}`
          : `Page ${index + 1}`,
        dropBefore: this.dropAt === index,
        dropAfter: this.dropAt === count && index === count - 1,
      };
    });
  }

  select = (index: number) => this.args.onSelect?.(index);

  // keyboard reordering
  onKey = (index: number, event: KeyboardEvent) => {
    if (!this.args.reorders || !event.altKey) return;
    const list = (event.currentTarget as HTMLElement).closest('ol');
    const rtl = list && getComputedStyle(list).direction === 'rtl';
    const forward = rtl ? 'ArrowLeft' : 'ArrowRight';
    const back = rtl ? 'ArrowRight' : 'ArrowLeft';
    const to =
      event.key === forward ? index + 1 : event.key === back ? index - 1 : NaN;
    if (Number.isNaN(to)) return;
    event.preventDefault();
    if (to < 0 || to >= this.args.pages.length) return;
    this.args.onMove?.(index, to);
    requestAnimationFrame(() =>
      list
        ?.querySelector<HTMLElement>(
          `[data-page-index="${to}"] .canon-page-strip-page`,
        )
        ?.focus(),
    );
  };

  onDragStart = (index: number, event: DragEvent) => {
    this.cancelPress();
    if (!this.args.reorders || !event.dataTransfer) {
      event.preventDefault();
      return;
    }
    this.#dragFrom = index;
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData(dragType, String(index));
    const paper = (event.currentTarget as HTMLElement).querySelector(
      '.canon-page-strip-paper',
    );
    if (paper) event.dataTransfer.setDragImage(paper, 0, 0);
  };

  onDragEnd = () => {
    this.#dragFrom = undefined;
    this.dropAt = undefined;
  };

  accepts(event: DragEvent) {
    const transfer = event.dataTransfer;
    if (!this.args.reorders || !transfer) return false;
    if (this.#dragFrom !== undefined) return true;
    if (!transfer.types.includes('Files')) return false;
    const types = [...transfer.items]
      .filter((item) => item.kind === 'file')
      .map((item) => item.type);
    return types.length === 0 || types.some((t) => matches(t, this.dropTypes));
  }

  destination(list: HTMLElement, x: number) {
    const rtl = getComputedStyle(list).direction === 'rtl';
    const items = [...list.querySelectorAll<HTMLElement>('[data-page-index]')];
    const index = items.findIndex((item) => {
      const box = item.getBoundingClientRect();
      const middle = box.left + box.width / 2;
      return rtl ? x > middle : x < middle;
    });
    return index === -1 ? items.length : index;
  }

  onDragOver = (event: DragEvent) => {
    if (!this.accepts(event)) return;
    event.preventDefault();
    event.dataTransfer!.dropEffect =
      this.#dragFrom !== undefined ? 'move' : 'copy';
    const at = this.destination(
      event.currentTarget as HTMLElement,
      event.clientX,
    );
    if (at !== this.dropAt) this.dropAt = at;
  };

  onDragLeave = (event: DragEvent) => {
    const list = event.currentTarget as HTMLElement;
    if (!list.contains(event.relatedTarget as Node | null))
      this.dropAt = undefined;
  };

  onDropFiles = (event: DragEvent) => {
    if (!this.accepts(event)) return;
    event.preventDefault();
    const destination = this.destination(
      event.currentTarget as HTMLElement,
      event.clientX,
    );
    const from = this.#dragFrom;
    this.onDragEnd();
    if (from !== undefined) {
      const to = Math.min(
        destination > from ? destination - 1 : destination,
        this.args.pages.length - 1,
      );
      if (to !== from) this.args.onMove?.(from, to);
      return;
    }
    const files = [...(event.dataTransfer?.files ?? [])].filter((file) =>
      matches(file.type, this.dropTypes),
    );
    if (files.length > 0) this.args.onDrop?.(destination, files);
  };

  openMenu(index: number, x: number, y: number) {
    const items = this.args.menu?.(index);
    const menu = this.#menu;
    if (!items?.length || !menu) return false;
    this.menuItems = items;
    menu.style.left = `${x}px`;
    menu.style.top = `${y}px`;
    menu.showPopover();
    requestAnimationFrame(() =>
      menu.querySelector<HTMLElement>('[role=menuitem]')?.focus(),
    );
    return true;
  }

  onContextMenu = (index: number, event: MouseEvent) => {
    let { clientX: x, clientY: y } = event;
    // the context menu key reports no position
    if (x === 0 && y === 0) {
      const box = (event.currentTarget as HTMLElement).getBoundingClientRect();
      x = box.left;
      y = box.bottom;
    }
    if (this.openMenu(index, x, y)) event.preventDefault();
  };

  // template-lint forbids binding pointerdown; a touch long press starts there
  longPress = modifier((button: HTMLElement, [index]: [number]) => {
    const start = (event: PointerEvent) => {
      if (event.pointerType !== 'touch' || !this.args.menu) return;
      const { clientX: x, clientY: y } = event;
      this.cancelPress();
      this.#press = window.setTimeout(
        () => this.openMenu(index, x, y),
        longPressMs,
      );
    };
    const ends = ['pointerup', 'pointercancel', 'pointerleave'] as const;
    button.addEventListener('pointerdown', start);
    ends.forEach((type) => button.addEventListener(type, this.cancelPress));
    return () => {
      this.cancelPress();
      button.removeEventListener('pointerdown', start);
      ends.forEach((type) =>
        button.removeEventListener(type, this.cancelPress),
      );
    };
  });

  cancelPress = () => {
    window.clearTimeout(this.#press);
  };

  choose = (item: CanonPageMenuItem) => {
    this.#menu?.hidePopover();
    item.action();
  };

  registerMenu = (element: HTMLElement) => {
    this.#menu = element;
  };

  willDestroy() {
    super.willDestroy();
    this.cancelPress();
  }

  <template>
    <div class="canon-page-strip" ...attributes>
      {{#if @pages.length}}
        <ol
          class="canon-page-strip-list"
          {{on "dragover" this.onDragOver}}
          {{on "dragleave" this.onDragLeave}}
          {{on "drop" this.onDropFiles}}
        >
          {{#each this.cells as |cell|}}
            <li
              class="canon-page-strip-cell
                {{if cell.lit 'canon-page-strip-cell--lit'}}
                {{if cell.dropBefore 'canon-page-strip-cell--drop-before'}}
                {{if cell.dropAfter 'canon-page-strip-cell--drop-after'}}"
              style={{cell.paperStyle}}
              data-page-index={{cell.index}}
              draggable={{if @reorders "true"}}
              {{on "dragstart" (fn this.onDragStart cell.index)}}
              {{on "dragend" this.onDragEnd}}
            >
              <button
                type="button"
                class="canon-page-strip-page"
                aria-label={{cell.label}}
                aria-current={{if cell.lit "true"}}
                aria-haspopup={{if @menu "menu"}}
                aria-keyshortcuts={{if
                  @reorders
                  "Alt+ArrowLeft Alt+ArrowRight"
                }}
                {{on "click" (fn this.select cell.index)}}
                {{on "keydown" (fn this.onKey cell.index)}}
                {{on "contextmenu" (fn this.onContextMenu cell.index)}}
                {{this.longPress cell.index}}
              >
                <span class="canon-page-strip-art">
                  <span class="canon-page-strip-stack">
                    {{#each cell.sheets as |sheet|}}
                      <span
                        class="canon-page-strip-sheet"
                        style={{sheet}}
                      ></span>
                    {{/each}}
                    <span class="canon-page-strip-paper">
                      {{#if cell.page.picture}}
                        <span class="canon-page-strip-clip" style={{cell.clip}}>
                          <img
                            class="canon-page-strip-picture"
                            src={{cell.page.picture}}
                            alt=""
                            draggable="false"
                            style={{cell.pictureStyle}}
                          />
                        </span>
                      {{/if}}
                      {{#if cell.dashed}}
                        <span
                          class="canon-page-strip-area"
                          style={{cell.dashed}}
                        ></span>
                      {{/if}}
                    </span>
                  </span>
                </span>
                <span
                  class="canon-page-strip-number
                    {{if cell.page.name 'canon-page-strip-number--named'}}"
                >{{cell.number}}</span>
                {{#if cell.page.name}}
                  <span class="canon-page-strip-name">{{cell.page.name}}</span>
                {{/if}}
              </button>
            </li>
          {{/each}}
        </ol>
      {{else}}
        <p class="canon-page-strip-empty">{{if @empty @empty "Pages"}}</p>
      {{/if}}
      <div
        class="canon-page-strip-menu"
        popover="auto"
        role="menu"
        {{register this.registerMenu}}
      >
        {{#each this.menuItems as |item|}}
          <button
            type="button"
            role="menuitem"
            class="canon-page-strip-menu-item
              {{if item.destructive 'canon-page-strip-menu-item--destructive'}}"
            {{on "click" (fn this.choose item)}}
          >{{item.title}}</button>
        {{/each}}
      </div>
    </div>
  </template>
}

function wholeRect(page: CanonPage): PageRect {
  return { x: 0, y: 0, width: page.size.width, height: page.size.height };
}
