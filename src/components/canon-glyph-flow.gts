import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import { glyphRows, type Frame, type GlyphKind } from '../lib/glyph-rows.ts';
import { curveEasing, glyphEased, glyphSettleMs } from '../lib/motion.ts';
import '../styles/tokens.css';
import './canon-glyph-flow.css';

export interface GlyphMetrics {
  /** Height of a row of glyphs. */
  height: number;
  rowGap: number;
  /** Room between glyphs in a row; a space glyph adds its own width. */
  gap: number;
}

export interface CanonGlyphFlowSignature<G> {
  Args: {
    glyphs: G[];
    metrics: GlyphMetrics;
    measure: (glyph: G) => number;
    kind: (glyph: G) => GlyphKind;
    /** Glyph kept in view with a row of context above it; none keeps the last row in view. */
    focus?: number;
    /** A change slides, grows and fades the glyphs; default true. */
    animated?: boolean;
    equals?: (a: G, b: G) => boolean;
    /** What the glyphs say, for assistive technology. */
    label?: string;
  };
  Blocks: {
    /** Paints one glyph into its box; the index is null for a glyph fading out. */
    default: [glyph: G, index: number | null];
    /** The picture with no glyphs, in the content area. */
    empty: [];
  };
  Element: HTMLDivElement;
}

interface Placed<G> {
  glyph: G;
  index: number;
  frame: Frame;
  from: Frame;
  appearing: boolean;
  moves: boolean;
  style: ReturnType<typeof htmlSafe>;
}

interface Previous<G> {
  glyphs: G[];
  target: Frame[];
  start: Frame[];
  appearing: boolean[];
  began: number;
  width: number;
  height: number;
  metrics?: GlyphMetrics;
  focus?: number;
}

const settleEasing = curveEasing(glyphEased);
const padding = 16;

function box(frame: Frame) {
  return htmlSafe(
    `left: ${frame.x}px; top: ${frame.y}px; width: ${frame.width}px; height: ${frame.height}px`,
  );
}

function intersects(a: Frame, b: Frame) {
  return (
    a.x < b.x + b.width &&
    b.x < a.x + a.width &&
    a.y < b.y + b.height &&
    b.y < a.y + a.height
  );
}

function still() {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

const glide = modifier(
  (
    element: HTMLElement,
    [placed]: [Pick<Placed<unknown>, 'frame' | 'from' | 'appearing' | 'moves'>],
  ) => {
    element.getAnimations().forEach((animation) => animation.cancel());
    if (!placed.moves) return;
    if (placed.appearing) {
      element.animate([{ opacity: 0 }, { opacity: 1 }], {
        duration: glyphSettleMs * 0.4,
      });
      element.animate(
        [{ transform: 'scale(0.55)' }, { transform: 'scale(1)' }],
        { duration: glyphSettleMs, easing: settleEasing },
      );
      return;
    }
    const dx = placed.from.x - placed.frame.x;
    const dy = placed.from.y - placed.frame.y;
    if (dx === 0 && dy === 0) return;
    element.animate(
      [{ transform: `translate(${dx}px, ${dy}px)` }, { transform: 'none' }],
      { duration: glyphSettleMs, easing: settleEasing },
    );
  },
);

const fade = modifier((element: HTMLElement) => {
  element.animate([{ opacity: 1 }, { opacity: 0 }], {
    duration: glyphSettleMs / 3,
    fill: 'forwards',
  });
});

/**
 * A transliteration drawn as glyphs in wrapped rows, the last row in view:
 * the banner of the text tools. On a change the glyphs that match at the
 * start and the end slide to their new places, new ones grow in and removed
 * ones fade.
 */
export default class CanonGlyphFlow<G> extends Component<
  CanonGlyphFlowSignature<G>
> {
  @tracked width = 0;
  @tracked height = 0;
  #previous: Previous<G> = {
    glyphs: [],
    target: [],
    start: [],
    appearing: [],
    began: 0,
    width: 0,
    height: 0,
  };

  measureSize = modifier((element: HTMLElement) => {
    const observer = new ResizeObserver(([entry]) => {
      if (!entry) return;
      const { width, height } = entry.contentRect;
      if (width !== this.width) this.width = width;
      if (height !== this.height) this.height = height;
    });
    observer.observe(element);
    return () => observer.disconnect();
  });

  get area(): Frame {
    return {
      x: padding,
      y: padding * 0.75,
      width: Math.max(0, this.width - padding * 2),
      height: Math.max(0, this.height - padding * 1.5),
    };
  }

  layout(glyphs: G[]): { frames: Frame[]; window: Frame } {
    const { metrics, measure, kind, focus } = this.args;
    const area = this.area;
    if (area.width <= 0 || glyphs.length === 0)
      return {
        frames: glyphs.map(() => ({ x: 0, y: 0, width: 0, height: 0 })),
        window: area,
      };
    const pitch = metrics.height + metrics.rowGap;
    const { frames, rows } = glyphRows(
      glyphs.map(measure),
      glyphs.map(kind),
      area.width,
      metrics.gap,
      metrics.height,
      pitch,
    );
    const fit = Math.max(1, Math.floor((area.height + metrics.rowGap) / pitch));
    const focusFrame = focus === undefined ? undefined : frames[focus];
    const focusRow =
      focusFrame === undefined
        ? undefined
        : Math.round(focusFrame.y / pitch) - (fit > 2 ? 1 : 0);
    const first =
      rows <= fit
        ? 0
        : Math.min(Math.max(0, focusRow ?? rows - fit), rows - fit);
    const block = Math.min(rows, fit) * pitch - metrics.rowGap;
    const y = area.y + Math.max(0, (area.height - block) / 2) - first * pitch;
    const widest = Math.max(0, ...frames.map((f) => f.x + f.width));
    const x = rows === 1 ? area.x + (area.width - widest) / 2 : area.x;
    return {
      frames: frames.map((f) => ({ ...f, x: f.x + x, y: f.y + y })),
      window: {
        x: 0,
        y: y + first * pitch - metrics.rowGap / 2,
        width: this.width,
        height: block + metrics.rowGap,
      },
    };
  }

  @cached
  get scene() {
    const { glyphs, metrics, focus } = this.args;
    const equals = this.args.equals ?? ((a: G, b: G) => a === b);
    const previous = this.#previous;
    const now = performance.now();
    const progress = Math.min(1, (now - previous.began) / glyphSettleMs);
    const eased = glyphEased(progress);
    const shown = previous.target.map((to, i) => {
      const from = previous.start[i];
      if (progress >= 1 || !from || previous.appearing[i]) return to;
      return {
        x: from.x + (to.x - from.x) * eased,
        y: from.y + (to.y - from.y) * eased,
        width: from.width + (to.width - from.width) * eased,
        height: from.height + (to.height - from.height) * eased,
      };
    });
    const { frames: target, window } = this.layout(glyphs);
    const moves =
      this.args.animated !== false &&
      previous.width > 0 &&
      this.width > 0 &&
      !still();

    const old = previous.glyphs;
    const same =
      old.length === glyphs.length &&
      old.every((g, i) => equals(g, glyphs[i]!));
    let start = target;
    let appearing = glyphs.map(() => false);
    let ghosts: { glyph: G; style: ReturnType<typeof htmlSafe> }[] = [];
    let animating = false;

    if (!same && moves) {
      let prefix = 0;
      while (
        prefix < Math.min(old.length, glyphs.length) &&
        equals(old[prefix]!, glyphs[prefix]!)
      )
        prefix += 1;
      const limit = Math.min(old.length, glyphs.length) - prefix;
      let suffix = 0;
      while (
        suffix < limit &&
        equals(
          old[old.length - 1 - suffix]!,
          glyphs[glyphs.length - 1 - suffix]!,
        )
      )
        suffix += 1;
      start = glyphs.map((_, i) => {
        if (i < prefix) return shown[i]!;
        if (i >= glyphs.length - suffix)
          return shown[i - glyphs.length + old.length]!;
        return target[i]!;
      });
      appearing = glyphs.map(
        (_, i) => i >= prefix && i < glyphs.length - suffix,
      );
      const bounds = { x: 0, y: 0, width: this.width, height: this.height };
      for (let i = prefix; i < old.length - suffix; i++) {
        const frame = shown[i];
        if (frame && frame.width > 0 && intersects(frame, bounds))
          ghosts.push({ glyph: old[i]!, style: box(frame) });
      }
      animating = true;
    } else if (same && moves) {
      const resettles =
        focus !== previous.focus ||
        (progress < 1 &&
          (metrics !== previous.metrics ||
            this.width !== previous.width ||
            this.height !== previous.height));
      if (resettles && shown.length === target.length) {
        start = shown;
        animating = true;
      }
    }
    if (!animating) ghosts = [];

    // the last scene is animation memory: frames to slide from, not rendered state
    // eslint-disable-next-line ember/no-side-effects
    this.#previous = {
      glyphs,
      target,
      start,
      appearing,
      began: animating ? now : previous.began,
      width: this.width,
      height: this.height,
      metrics,
      focus,
    };

    const items: Placed<G>[] = [];
    glyphs.forEach((glyph, index) => {
      const frame = target[index]!;
      if (frame.width <= 0) return;
      items.push({
        glyph,
        index,
        frame,
        from: start[index]!,
        appearing: appearing[index]!,
        moves: animating,
        style: box(frame),
      });
    });
    const bottom = this.height - (window.y + window.height);
    return {
      items,
      ghosts,
      empty: glyphs.length === 0,
      clip: htmlSafe(`clip-path: inset(${window.y}px 0 ${bottom}px 0)`),
      area: box(this.area),
    };
  }

  <template>
    <div
      class="canon-glyph-flow"
      role="img"
      aria-label={{@label}}
      {{this.measureSize}}
      ...attributes
    >
      {{#if this.scene.empty}}
        <div class="canon-glyph-flow-empty" style={{this.scene.area}}>{{yield
            to="empty"
          }}</div>
      {{/if}}
      <div
        class="canon-glyph-flow-glyphs"
        style={{this.scene.clip}}
        aria-hidden="true"
      >
        {{#each this.scene.ghosts as |ghost|}}
          <div
            class="canon-glyph-flow-glyph"
            style={{ghost.style}}
            {{fade}}
          >{{yield ghost.glyph null}}</div>
        {{/each}}
        {{#each this.scene.items key="index" as |item|}}
          <div
            class="canon-glyph-flow-glyph"
            style={{item.style}}
            {{glide item}}
          >{{yield item.glyph item.index}}</div>
        {{/each}}
      </div>
    </div>
  </template>
}
