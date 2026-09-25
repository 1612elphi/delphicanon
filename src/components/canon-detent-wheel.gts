import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import type Owner from '@ember/owner';
import grabPan from '../modifiers/canon-grab-pan.ts';
import {
  advance,
  detent,
  drum,
  goal,
  isSettled,
  placement,
  tappedRows,
  wrapped,
  type DetentMotion,
  type DetentRange,
} from '../lib/detent-wheel.ts';
import '../styles/tokens.css';
import './canon-detent-wheel.css';

export interface CanonDetentWheelSignature {
  Args: {
    count: number;
    /** The centred row. A change turns the wheel there the shorter way round. */
    selected: number;
    /** Default 40. */
    rowHeight?: number;
    /** The centred row changed, by a drag, a fling, a tap, the wheel or the keys, once per row crossed. */
    onSelect?: (index: number) => void;
    /** Accessible reading of a row. */
    text?: (index: number) => string;
    label?: string;
    labelledBy?: string;
  };
  /** Paints one row: its index and `focus`, 1 on the centre line and 0 a row or more away. */
  Blocks: { default: [index: number, focus: number] };
  Element: HTMLDivElement;
}

/** Pointer travel in px under which a release is a tap. */
const tapSlop = 6;
/** Wheel events further apart than this end a wheel turn. */
const wheelRestMs = 120;

/**
 * Rows on a drum, turned by a vertical drag or the mouse wheel, with inertia;
 * it comes to rest on a row, and the centred row is the selection. Rows
 * flatten and fade with their angle from the centre. It loops when there are
 * more rows than fit; otherwise the ends pull back like rubber.
 */
export default class CanonDetentWheel extends Component<CanonDetentWheelSignature> {
  @tracked position: number;
  @tracked height = 0;
  @tracked selected: number;
  #motion: DetentMotion;
  #count: number;
  #asked: number;
  #frame?: number;
  #last = 0;
  #dragging = false;
  #drag = { startY: 0, lastY: 0, travel: 0, samples: [] as [number, number][] };
  #wheelTimer?: number;

  constructor(owner: Owner, args: CanonDetentWheelSignature['Args']) {
    super(owner, args);
    this.#count = args.count;
    this.#asked = args.selected;
    this.selected = this.clampIndex(args.selected);
    this.position = this.selected;
    this.#motion = {
      position: this.selected,
      velocity: 0,
      target: this.selected,
    };
  }

  get rowHeight() {
    return this.args.rowHeight ?? 40;
  }

  get geometry() {
    return drum(this.height, this.rowHeight);
  }

  get loops() {
    return this.args.count > this.geometry.fitting;
  }

  get range(): DetentRange {
    return this.loops ? undefined : [0, Math.max(this.args.count - 1, 0)];
  }

  get rows() {
    const { count } = this.args;
    if (count === 0 || this.height === 0) return [];
    const { radius, step } = this.geometry;
    const half = Math.floor(detent.reach / step) + 1;
    const centre = Math.round(this.position);
    const rows = [];
    for (let index = centre - half; index <= centre + half; index++) {
      if (!this.loops && (index < 0 || index >= count)) continue;
      const offset = index - this.position;
      if (Math.abs(offset) * step > detent.reach) continue;
      const { y, scaleY, opacity, focus } = placement(offset, step, radius);
      rows.push({
        key: index,
        index: wrapped(index, count),
        focus,
        style: htmlSafe(
          `transform: translateY(${y}px) scaleY(${scaleY}); opacity: ${opacity}`,
        ),
      });
    }
    return rows;
  }

  get style() {
    return htmlSafe(`--canon-detent-row: ${this.rowHeight}px`);
  }

  get valueText() {
    return this.args.count > 0 ? this.args.text?.(this.selected) : undefined;
  }

  clampIndex(index: number) {
    return this.args.count === 0
      ? 0
      : Math.min(Math.max(index, 0), this.args.count - 1);
  }

  place(position: number) {
    this.position = position;
    const nearest = wrapped(Math.round(position), this.args.count);
    if (this.args.count === 0 || nearest === this.selected) return;
    this.selected = nearest;
    this.#asked = nearest;
    this.args.onSelect?.(nearest);
  }

  run() {
    if (this.#frame !== undefined) return;
    this.#last = performance.now();
    const frame = (now: number) => {
      const seconds = Math.min((now - this.#last) / 1000, 1 / 30);
      this.#last = now;
      this.#motion = advance(this.#motion, seconds, this.range);
      this.place(this.#motion.position);
      if (isSettled(this.#motion)) this.#frame = undefined;
      else this.#frame = requestAnimationFrame(frame);
    };
    this.#frame = requestAnimationFrame(frame);
  }

  stop() {
    if (this.#frame !== undefined) cancelAnimationFrame(this.#frame);
    this.#frame = undefined;
  }

  /** Turns to `index`, the shorter way round when the wheel loops. */
  select(index: number, animated: boolean) {
    if (this.args.count === 0) return;
    const to = goal(this.#motion.position, index, this.args.count, this.loops);
    if (animated && !reducedMotion()) {
      this.#motion = { ...this.#motion, target: to };
      this.run();
    } else {
      this.stop();
      this.#motion = { position: to, velocity: 0, target: to };
      this.place(to);
    }
  }

  /** Moves by `rows` of drag, pulled short past the ends. */
  drag(rows: number) {
    const { range } = this;
    const { position } = this.#motion;
    const outside = range && (position < range[0] || position > range[1]);
    this.#motion = {
      position: position + (outside ? rows * detent.rubber : rows),
      velocity: 0,
    };
    this.place(this.#motion.position);
  }

  release(velocity: number) {
    this.#motion = { ...this.#motion, velocity, target: undefined };
    this.run();
  }

  measure = modifier((element: HTMLElement) => {
    const observer = new ResizeObserver(([entry]) => {
      this.height = entry?.contentRect.height ?? 0;
    });
    observer.observe(element);
    const wheel = (event: WheelEvent) => {
      if (this.args.count === 0) return;
      event.preventDefault();
      this.stop();
      this.drag(
        event.deltaMode === WheelEvent.DOM_DELTA_PIXEL
          ? event.deltaY / this.rowHeight
          : Math.sign(event.deltaY),
      );
      window.clearTimeout(this.#wheelTimer);
      this.#wheelTimer = window.setTimeout(() => this.release(0), wheelRestMs);
    };
    element.addEventListener('wheel', wheel, { passive: false });
    return () => {
      observer.disconnect();
      element.removeEventListener('wheel', wheel);
    };
  });

  // runs after render when @count or @selected change; tracked writes wait for a microtask
  follow = modifier((_: HTMLElement, [count, selected]: [number, number]) => {
    if (count !== this.#count) {
      this.#count = count;
      this.#asked = selected;
      const index = this.clampIndex(selected);
      queueMicrotask(() => {
        this.stop();
        this.selected = index;
        this.#motion = { position: index, velocity: 0, target: index };
        this.position = index;
      });
    } else if (selected !== this.#asked) {
      this.#asked = selected;
      queueMicrotask(() => {
        if (selected !== this.selected && !this.#dragging)
          this.select(this.clampIndex(selected), true);
      });
    }
  });

  grabs = () => this.args.count > 0;

  begin = (event: PointerEvent) => {
    this.stop();
    this.#dragging = true;
    this.#drag = {
      startY: event.clientY,
      lastY: event.clientY,
      travel: 0,
      samples: [[event.timeStamp, event.clientY]],
    };
  };

  move = (event: PointerEvent) => {
    const drag = this.#drag;
    const dy = event.clientY - drag.lastY;
    drag.lastY = event.clientY;
    drag.travel = Math.max(drag.travel, Math.abs(event.clientY - drag.startY));
    drag.samples = [
      ...drag.samples.filter(([time]) => event.timeStamp - time < 100),
      [event.timeStamp, event.clientY],
    ];
    this.drag(-dy / this.rowHeight);
  };

  end = (event: PointerEvent) => {
    this.#dragging = false;
    const drag = this.#drag;
    if (drag.travel < tapSlop) {
      this.tap(event);
      return;
    }
    const [first] = drag.samples;
    const seconds = first ? (event.timeStamp - first[0]) / 1000 : 0;
    const pxPerSecond =
      first && seconds > 0 ? (event.clientY - first[1]) / seconds : 0;
    const speed = (-pxPerSecond / this.rowHeight) * detent.flingCarry;
    this.release(
      Math.min(Math.max(speed, -detent.flingLimit), detent.flingLimit),
    );
  };

  tap(event: PointerEvent) {
    const box = (event.currentTarget as HTMLElement).getBoundingClientRect();
    const { radius, step } = this.geometry;
    const rows = tappedRows(
      event.clientY - (box.top + box.height / 2),
      radius,
      step,
    );
    let to = Math.round(this.#motion.position) + rows;
    const { range } = this;
    if (range) to = Math.min(Math.max(to, range[0]), range[1]);
    this.#motion = { ...this.#motion, target: to };
    this.run();
  }

  key = (event: KeyboardEvent) => {
    const { count } = this.args;
    if (count === 0) return;
    const last = count - 1;
    const next: Record<string, number> = {
      ArrowDown: this.selected + 1,
      ArrowRight: this.selected + 1,
      ArrowUp: this.selected - 1,
      ArrowLeft: this.selected - 1,
      Home: 0,
      End: last,
    };
    const to = next[event.key];
    if (to === undefined) return;
    event.preventDefault();
    if (!this.loops && (to < 0 || to > last)) return;
    this.select(wrapped(to, count), true);
  };

  willDestroy() {
    super.willDestroy();
    this.stop();
    window.clearTimeout(this.#wheelTimer);
  }

  <template>
    {{! template-lint-disable require-presentational-children }}
    <div
      class="canon-detent-wheel"
      style={{this.style}}
      role="slider"
      tabindex="0"
      aria-orientation="vertical"
      aria-valuemin="0"
      aria-valuemax={{maxIndex @count}}
      aria-valuenow={{this.selected}}
      aria-valuetext={{this.valueText}}
      aria-label={{@label}}
      aria-labelledby={{@labelledBy}}
      {{this.measure}}
      {{this.follow @count @selected}}
      {{grabPan
        grabs=this.grabs
        onBegin=this.begin
        onMove=this.move
        onEnd=this.end
      }}
      {{on "keydown" this.key}}
      ...attributes
    >
      {{#each this.rows key="key" as |row|}}
        <div
          class="canon-detent-wheel-slot"
          style={{row.style}}
          aria-hidden="true"
        >{{yield row.index row.focus}}</div>
      {{/each}}
    </div>
  </template>
}

function maxIndex(count: number) {
  return Math.max(count - 1, 0);
}

function reducedMotion() {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}
