import type { Metrics } from './typeset.ts';

const fallbackFamily =
  'ui-serif, "New York", "Iowan Old Style", Georgia, "Times New Roman", serif';
let context: CanvasRenderingContext2D | null | undefined;
let family: string | undefined;
const cache = new Map<string, { width: number; ascent: number; descent: number }>();

function mathFamily(): string {
  family ??=
    getComputedStyle(document.documentElement)
      .getPropertyValue('--canon-math-font')
      .trim() || fallbackFamily;
  return family;
}

function measure(text: string, italic: boolean, size: number) {
  const key = `${text}|${italic}|${size}`;
  const hit = cache.get(key);
  if (hit) return hit;
  // ponytail: unbounded cache cleared wholesale; typing makes a few hundred entries at most
  if (cache.size > 2000) cache.clear();
  context ??= document.createElement('canvas').getContext('2d');
  let result = { width: text.length * size * 0.5, ascent: size * 0.7, descent: 0 };
  if (context) {
    context.font = `${italic ? 'italic ' : ''}${size}px ${mathFamily()}`;
    const m = context.measureText(text);
    result = {
      width: m.width,
      ascent: m.actualBoundingBoxAscent,
      descent: m.actualBoundingBoxDescent,
    };
  }
  cache.set(key, result);
  return result;
}

/** Glyph metrics from a canvas in the maths serif (`--canon-math-font`). */
export const canvasMetrics: Metrics = {
  measure,
  xHeight: (size, italic) => measure('x', italic, size).ascent,
};

export { mathFamily };
