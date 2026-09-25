import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import CanonMathKey from './canon-math-key.gts';
import CanonMathTabs from './canon-math-tabs.gts';
import { opensSlot, type Key } from '../lib/math/expression.ts';
import {
  glideSpring,
  keyHeights,
  label,
  labelShare,
  menuScale,
  nameScale,
  pages,
  returnDelay,
  spoken,
  tabHeights,
  type Family,
  type Spec,
} from '../lib/math/keypad.ts';
import { canvasMetrics } from '../lib/math/measure.ts';
import { springEasing } from '../lib/motion.ts';
import { Typesetter, type Box } from '../lib/math/typeset.ts';
import '../styles/tokens.css';
import './canon-math-keypad.css';
import { Delete as backspace } from 'lucide-static';
import CanonIcon from './canon-icon.gts';

export interface CanonMathKeypadSignature {
  Args: {
    /** The first letter key, and the variable of d/dx, ∫ and lim; default x. */
    variable?: string;
    /** The short keys, for a short window. */
    short?: boolean;
    onKey?: (key: Key) => void;
    onDone?: () => void;
  };
  Element: HTMLDivElement;
}

interface PlacedKey {
  spec: Spec;
  face: Box;
  label: string;
  id: string;
  style: ReturnType<typeof htmlSafe>;
}

interface Menu {
  keys: { key: Key; face: Box; label: string }[];
  family: Family;
  page: number;
  anchor: HTMLElement;
  cell: { width: number; height: number };
}

const DeleteIcon = <template><CanonIcon @svg={{backspace}} /></template>;

/**
 * Maths keys on four swipeable pages (numbers and operators, functions,
 * calculus, letters and constants), with delete, clear and Done beside every
 * page. Hyperbolic and reciprocal trig sit in submenus. A slot key typed on a
 * later page returns to the numbers, since the slot usually takes a number
 * next.
 */
export default class CanonMathKeypad extends Component<CanonMathKeypadSignature> {
  @tracked progress = 0;
  @tracked pageWidth = 0;
  @tracked menu?: Menu;
  #pager?: HTMLElement;
  #glide?: number;
  #tracking = false;

  get variable() {
    return this.args.variable ?? 'x';
  }

  get keyHeight() {
    return this.args.short ? keyHeights.short : keyHeights.regular;
  }

  get labelSize() {
    return Math.round(this.keyHeight * labelShare);
  }

  get page() {
    return Math.min(Math.max(Math.round(this.progress), 0), 3);
  }

  get style() {
    return htmlSafe(
      `--canon-math-key-height: ${this.keyHeight}px; --canon-math-tab-height: ${this.args.short ? tabHeights.short : tabHeights.regular}px`,
    );
  }

  /** Faces are set once per variable and key size. */
  @cached
  get built(): PlacedKey[][] {
    const size = this.labelSize;
    return pages(this.variable).map((specs, page) =>
      specs.map((spec) => ({
        spec,
        face: spec.menu
          ? new Typesetter(canvasMetrics, size * menuScale).text(
              spec.menu.title,
            )
          : label(spec.key, this.variable, size * spec.scale, canvasMetrics),
        label: spec.menu?.title ?? spoken(spec.key, this.variable),
        id: `${page}-${spec.x}-${spec.y}`,
        style: htmlSafe(
          `grid-column: ${spec.x + 1} / span ${spec.w}; grid-row: ${spec.y + 1} / span ${spec.h}; --canon-math-x: ${spec.x}; --canon-math-w: ${spec.w}`,
        ),
      })),
    );
  }

  get pages() {
    return this.built.map((keys, index) => {
      const offset = index - this.progress;
      return {
        keys,
        index,
        away: index !== this.page,
        style: htmlSafe(
          `--canon-math-offset-px: ${offset * this.pageWidth}px; --canon-math-lead: ${offset > 0 ? 1 : 0}; --canon-math-fade: ${1 - 0.7 * Math.min(1, Math.abs(offset))}`,
        ),
      };
    });
  }

  get clearFace() {
    return label(
      { kind: 'clear' },
      this.variable,
      this.labelSize * 0.9,
      canvasMetrics,
    );
  }

  type = (key: Key, page: number) => {
    this.closeMenu();
    this.args.onKey?.(key);
    if (page === 0 || !opensSlot(key)) return;
    window.setTimeout(() => {
      if (this.page !== page || this.#glide !== undefined || this.#tracking)
        return;
      this.show(0);
    }, returnDelay * 1000);
  };

  delete = () => this.args.onKey?.({ kind: 'delete' });
  clear = () => this.args.onKey?.({ kind: 'clear' });
  done = () => this.args.onDone?.();

  // MARK: paging

  show = (index: number) => {
    this.closeMenu();
    const pager = this.#pager;
    if (!pager) return;
    const width = pager.clientWidth;
    const target = Math.min(Math.max(index, 0), 3) * width;
    this.#stopGlide();
    if (width === 0 || matchMedia('(prefers-reduced-motion: reduce)').matches) {
      pager.scrollLeft = target;
      return;
    }
    const from = pager.scrollLeft;
    const start = performance.now();
    const omega = (2 * Math.PI) / glideSpring.response;
    const zeta = glideSpring.damping;
    const damped = omega * Math.sqrt(1 - zeta * zeta);
    pager.classList.add('canon-math-keypad-pager--gliding');
    const frame = (now: number) => {
      const t = (now - start) / 1000;
      const envelope = Math.exp(-zeta * omega * t);
      const x =
        target +
        (from - target) *
          envelope *
          (Math.cos(damped * t) +
            ((zeta * omega) / damped) * Math.sin(damped * t));
      if (t > 1.2 || (t > 0.2 && Math.abs(x - target) < 0.3)) {
        pager.scrollLeft = target;
        this.#stopGlide();
        return;
      }
      pager.scrollLeft = x;
      this.#glide = requestAnimationFrame(frame);
    };
    this.#glide = requestAnimationFrame(frame);
  };

  #stopGlide() {
    if (this.#glide !== undefined) cancelAnimationFrame(this.#glide);
    this.#glide = undefined;
    this.#pager?.classList.remove('canon-math-keypad-pager--gliding');
  }

  pager = modifier((pager: HTMLElement) => {
    this.#pager = pager;
    const scrolled = () => {
      const width = pager.clientWidth;
      if (width === 0) return;
      this.pageWidth = width;
      this.progress = pager.scrollLeft / width;
    };
    const down = () => {
      this.#tracking = true;
      this.#stopGlide();
    };
    const up = () => (this.#tracking = false);
    const resize = new ResizeObserver(() => {
      if (this.#glide === undefined)
        pager.scrollLeft = this.page * pager.clientWidth;
      scrolled();
    });
    resize.observe(pager);
    pager.addEventListener('scroll', scrolled, { passive: true });
    pager.addEventListener('pointerdown', down);
    pager.addEventListener('wheel', down, { passive: true });
    pager.addEventListener('pointerup', up);
    pager.addEventListener('pointercancel', up);
    pager.addEventListener('scrollend', up);
    return () => {
      this.#stopGlide();
      resize.disconnect();
      pager.removeEventListener('scroll', scrolled);
      pager.removeEventListener('pointerdown', down);
      pager.removeEventListener('wheel', down);
      pager.removeEventListener('pointerup', up);
      pager.removeEventListener('pointercancel', up);
      pager.removeEventListener('scrollend', up);
    };
  });

  // MARK: submenu

  openMenu = (placed: PlacedKey, page: number) => {
    const menu = placed.spec.menu;
    const anchor = this.#pager?.querySelector<HTMLElement>(
      `[data-canon-math-key="${placed.id}"]`,
    );
    if (!menu || !anchor) return;
    const size = this.labelSize;
    this.menu = {
      keys: menu.keys.map((key) => ({
        key,
        face: label(key, this.variable, size * nameScale, canvasMetrics),
        label: spoken(key, this.variable),
      })),
      family: placed.spec.family,
      page,
      anchor,
      cell: {
        width: Math.max(64, anchor.offsetWidth / 3 + 12),
        height: this.keyHeight,
      },
    };
  };

  closeMenu = () => {
    this.menu = undefined;
  };

  get menuStyle() {
    const menu = this.menu;
    if (!menu) return undefined;
    const per = 3;
    const count = Math.ceil(menu.keys.length / per);
    return htmlSafe(
      `--canon-math-menu-cell: ${menu.cell.width}px; --canon-math-key-height: ${menu.cell.height}px; grid-template-rows: repeat(${count}, ${menu.cell.height}px)`,
    );
  }

  /** Opens over its key, growing out of the key's top edge; a touch elsewhere or Escape closes it. */
  placeMenu = modifier((panel: HTMLElement, [menu]: [Menu]) => {
    const root = panel.parentElement!;
    const box = root.getBoundingClientRect();
    const anchor = menu.anchor.getBoundingClientRect();
    const width = panel.offsetWidth;
    const height = panel.offsetHeight;
    const midX = anchor.left + anchor.width / 2 - box.left;
    const left = Math.min(Math.max(midX - width / 2, 6), box.width - 6 - width);
    const top = anchor.top - box.top - height - 6;
    panel.style.insetInlineStart = `${left}px`;
    panel.style.insetBlockStart = `${top}px`;
    if (!matchMedia('(prefers-reduced-motion: reduce)').matches) {
      const dx = (midX - (left + width / 2)) * 0.6;
      const dy = (anchor.top - box.top - (top + height / 2)) * 0.6;
      panel.animate(
        [
          { transform: `translate(${dx}px, ${dy}px) scale(0.4)`, opacity: 0 },
          { transform: 'none', opacity: 1 },
        ],
        { duration: 340, easing: springEasing(0.74) },
      );
    }
    panel.querySelector<HTMLElement>('button')?.focus({ preventScroll: true });
    const outside = (event: PointerEvent) => {
      if (!panel.contains(event.target as Node)) this.closeMenu();
    };
    const escape = (event: KeyboardEvent) => {
      if (event.key !== 'Escape') return;
      event.preventDefault();
      event.stopPropagation();
      this.closeMenu();
      menu.anchor.focus({ preventScroll: true });
    };
    document.addEventListener('pointerdown', outside, true);
    document.addEventListener('keydown', escape, true);
    return () => {
      document.removeEventListener('pointerdown', outside, true);
      document.removeEventListener('keydown', escape, true);
    };
  });

  willDestroy() {
    super.willDestroy();
    this.#stopGlide();
  }

  <template>
    <div class="canon-math-keypad" style={{this.style}} ...attributes>
      <CanonMathTabs @progress={{this.progress}} @onSelect={{this.show}} />
      <div class="canon-math-keypad-pager" {{this.pager}}>
        {{#each this.pages as |page|}}
          <div
            class="canon-math-keypad-page"
            style={{page.style}}
            inert={{page.away}}
          >
            {{#each page.keys as |placed|}}
              {{#if placed.spec.menu}}
                <CanonMathKey
                  @face={{placed.face}}
                  @family={{placed.spec.family}}
                  @label={{placed.label}}
                  @menu={{true}}
                  @onClick={{fn this.openMenu placed page.index}}
                  style={{placed.style}}
                  data-canon-math-key={{placed.id}}
                />
              {{else}}
                <CanonMathKey
                  @face={{placed.face}}
                  @family={{placed.spec.family}}
                  @label={{placed.label}}
                  @onClick={{fn this.type placed.spec.key page.index}}
                  style={{placed.style}}
                  data-canon-math-key={{placed.id}}
                />
              {{/if}}
            {{/each}}
          </div>
        {{/each}}
      </div>
      <div class="canon-math-keypad-spine">
        <CanonMathKey
          @family="operation"
          @label="Delete"
          @repeats={{true}}
          @onClick={{this.delete}}
        ><DeleteIcon /></CanonMathKey>
        <CanonMathKey
          @face={{this.clearFace}}
          @family="clear"
          @label="Clear"
          @onClick={{this.clear}}
        />
        <CanonMathKey
          class="canon-math-keypad-done"
          @family="done"
          @label="Done"
          @onClick={{this.done}}
        >Done</CanonMathKey>
      </div>
      {{#if this.menu}}
        <div
          class="canon-math-submenu canon-math-key--{{this.menu.family}}"
          role="menu"
          style={{this.menuStyle}}
          {{this.placeMenu this.menu}}
        >
          {{#each this.menu.keys as |item|}}
            <CanonMathKey
              @face={{item.face}}
              @family={{this.menu.family}}
              @label={{item.label}}
              @onClick={{fn this.type item.key this.menu.page}}
              role="menuitem"
            />
          {{/each}}
        </div>
      {{/if}}
    </div>
  </template>
}
