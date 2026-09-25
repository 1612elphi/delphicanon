import {
  grown,
  morphEasing,
  settleSeconds,
  type Keyed,
  type Placed,
} from './morph.ts';
import type { Atom, Box, Rect } from './typeset.ts';

const ns = 'http://www.w3.org/2000/svg';

function element<K extends keyof SVGElementTagNameMap>(
  tag: K,
  attributes: Record<string, string | number>,
): SVGElementTagNameMap[K] {
  const el = document.createElementNS(ns, tag);
  for (const [name, value] of Object.entries(attributes))
    el.setAttribute(name, String(value));
  return el;
}

const r = (n: number) => Math.round(n * 100) / 100;

function stroked(d: string, weight: number, join: string, cap = 'butt') {
  return element('path', {
    d,
    fill: 'none',
    stroke: 'currentColor',
    'stroke-width': r(weight),
    'stroke-linejoin': join,
    'stroke-linecap': cap,
  });
}

/** `atom` drawn at `frame` (CanonMath.draw); a glyph run scales with the frame's height. */
export function atomElement(atom: Atom, frame: Rect = atom.frame): SVGElement {
  const { x, y, width: w, height: h } = frame;
  const mark = atom.mark;
  let el: SVGElement;
  switch (mark.m) {
    case 'glyphs':
      el = element('text', {
        x: r(x),
        y: r(y),
        'font-size': r(h),
        ...(mark.italic ? { 'font-style': 'italic' } : {}),
      });
      el.textContent = mark.text;
      break;
    case 'rule':
      el = element('rect', { x: r(x), y: r(y), width: r(w), height: r(h) });
      break;
    case 'paren': {
      const [near, far] = mark.open ? [x + w, x] : [x, x + w];
      const inset = w * 0.15 * (mark.open ? -1 : 1);
      el = stroked(
        `M${r(near + inset)} ${r(y)}Q${r(far - inset * 2)} ${r(y + h / 2)} ${r(near + inset)} ${r(y + h)}`,
        atom.weight,
        'round',
        'round',
      );
      break;
    }
    case 'corner': {
      const stem = mark.open ? x + w * 0.3 : x + w - w * 0.3;
      const foot = mark.open ? x + w : x;
      const [start, end] = mark.floor ? [y, y + h] : [y + h, y];
      el = stroked(
        `M${r(stem)} ${r(start)}L${r(stem)} ${r(end)}L${r(foot)} ${r(end)}`,
        atom.weight,
        'miter',
      );
      break;
    }
    case 'radical':
      el = stroked(
        `M${r(x)} ${r(y + h * 0.6)}L${r(x + w * 0.22)} ${r(y + h * 0.5)}L${r(x + w * 0.5)} ${r(y + h)}L${r(x + w)} ${r(y)}`,
        atom.weight,
        'round',
        'round',
      );
      break;
    case 'hole': {
      const half = atom.weight / 2;
      el = element('rect', {
        x: r(x + half),
        y: r(y + half),
        width: r(Math.max(0, w - atom.weight)),
        height: r(Math.max(0, h - atom.weight)),
        fill: 'none',
        stroke: 'currentColor',
        'stroke-width': r(atom.weight),
        'stroke-dasharray': `${r(atom.weight * 2)} ${r(atom.weight * 1.5)}`,
      });
      break;
    }
  }
  el.setAttribute('class', `canon-math-ink--${atom.ink}`);
  return el;
}

/** Draws `box` into `svg` at its own size; the viewBox lets CSS scale it down to fit. */
export function drawBox(svg: SVGSVGElement, box: Box): void {
  const width = Math.max(box.width, 0.01);
  const height = Math.max(box.height, 0.01);
  svg.setAttribute('viewBox', `0 ${r(-box.ascent)} ${r(width)} ${r(height)}`);
  svg.style.setProperty('--canon-math-width', `${Math.ceil(width)}px`);
  svg.style.setProperty('--canon-math-height', `${Math.ceil(height)}px`);
  svg.replaceChildren(...box.atoms.map((atom) => atomElement(atom)));
}

interface Shown {
  el: SVGElement;
  placed: Placed;
}

function still(): boolean {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

/** The transform that draws an element set at `rest` at `rect` instead. */
function toward(placed: Placed, rect: Rect): string {
  const rest = placed.frame;
  const glyph = placed.atom.mark.m === 'glyphs';
  const sy = rest.height > 0 ? rect.height / rest.height : 1;
  const sx = glyph ? sy : rest.width > 0 ? rect.width / rest.width : 1;
  return `translate(${r(rect.x - rest.x * sx)}px, ${r(rect.y - rest.y * sy)}px) scale(${sx}, ${sy})`;
}

const identity = 'translate(0px, 0px) scale(1, 1)';

/** Where an element is drawn now, mid-animation or not. */
function current(shown: Shown): { frame: Rect; alpha: number } {
  const style = getComputedStyle(shown.el);
  const alpha = Number(style.opacity);
  const rest = shown.placed.frame;
  if (style.transform === 'none' || !style.transform)
    return { frame: rest, alpha };
  const m = new DOMMatrixReadOnly(style.transform);
  return {
    frame: {
      x: m.a * rest.x + m.e,
      y: m.d * rest.y + m.f,
      width: m.a * rest.width,
      height: m.d * rest.height,
    },
    alpha,
  };
}

/**
 * Typeset atoms moving from one arrangement to the next (CanonMathMorph): an
 * atom whose key stays slides and resizes on a damped spring, a new one grows
 * in, a removed one fades. Draws into an SVG group in pixel coordinates.
 */
export class MathMorph {
  #shown = new Map<string, Shown>();
  #leaving: Shown[] = [];
  #easing = morphEasing();

  constructor(private group: SVGGElement) {}

  /** Renames the shown atoms, so the next `show` moves them to where their new keys are. */
  rename(transform: (key: string) => string): void {
    const renamed = new Map<string, Shown>();
    for (const [key, shown] of this.#shown) {
      const next = transform(key);
      if (!renamed.has(next)) renamed.set(next, shown);
    }
    this.#shown = renamed;
  }

  show(next: Keyed[], animated: boolean): void {
    const moving = animated && this.group.isConnected && !still();
    const ms = settleSeconds * 1000;
    for (const gone of this.#leaving) gone.el.remove();
    this.#leaving = [];
    const target = new Map(next.map((k) => [k.key, k.placed]));
    const leaving: Shown[] = [];
    for (const [key, shown] of this.#shown) {
      if (target.has(key)) continue;
      if (!moving) continue;
      const now = current(shown);
      shown.el.getAnimations().forEach((a) => a.cancel());
      shown.el.style.opacity = '0';
      const from = { ...shown.placed, frame: now.frame };
      shown.el.animate(
        [
          { transform: toward(shown.placed, now.frame) },
          { transform: toward(shown.placed, grown(from, 0.8)) },
        ],
        { duration: ms, easing: 'linear' },
      );
      shown.el.animate(
        [
          { opacity: now.alpha, offset: 0 },
          { opacity: 0, offset: 0.4 },
          { opacity: 0, offset: 1 },
        ],
        { duration: ms },
      );
      leaving.push(shown);
    }
    const shownNext = new Map<string, Shown>();
    const elements: SVGElement[] = [];
    for (const { key, placed } of next) {
      if (shownNext.has(key)) continue;
      const el = atomElement(placed.atom, placed.frame);
      el.style.opacity = String(placed.alpha);
      const old = this.#shown.get(key);
      if (moving && old) {
        const now = current(old);
        el.animate(
          [{ transform: toward(placed, now.frame) }, { transform: identity }],
          { duration: ms, easing: this.#easing },
        );
        el.animate([{ opacity: now.alpha }, { opacity: placed.alpha }], {
          duration: ms,
        });
      } else if (moving) {
        el.animate(
          [
            { transform: toward(placed, grown(placed, 0.6)) },
            { transform: identity },
          ],
          { duration: ms, easing: this.#easing },
        );
        el.animate(
          [
            { opacity: 0, offset: 0 },
            { opacity: 0, offset: 0.12 },
            { opacity: placed.alpha, offset: 0.62 },
            { opacity: placed.alpha, offset: 1 },
          ],
          { duration: ms },
        );
      }
      shownNext.set(key, { el, placed });
      elements.push(el);
    }
    this.#shown = shownNext;
    this.#leaving = leaving;
    this.group.replaceChildren(...leaving.map((s) => s.el), ...elements);
    if (leaving.length)
      window.setTimeout(() => {
        if (this.#leaving !== leaving) return;
        leaving.forEach((s) => s.el.remove());
        this.#leaving = [];
      }, ms);
  }

  /** Jumps to the end. */
  land(): void {
    for (const gone of this.#leaving) gone.el.remove();
    this.#leaving = [];
    for (const { el } of this.#shown.values())
      el.getAnimations().forEach((a) => a.finish());
  }
}

/** Pointer capture that tolerates a pointer already gone, as a synthetic event's is. */
export function capture(element: Element, pointerId: number): void {
  try {
    element.setPointerCapture(pointerId);
  } catch {
    // the pointer ended before the capture
  }
}
