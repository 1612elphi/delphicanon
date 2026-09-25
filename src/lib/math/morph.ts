import type { Atom, Mark, Rect } from './typeset.ts';

export interface Placed {
  atom: Atom;
  /** Where the atom is drawn; `atom.frame` keeps its set size. */
  frame: Rect;
  alpha: number;
}

export interface Keyed {
  key: string;
  placed: Placed;
}

export const settleSeconds = 0.55;

function markKey(mark: Mark): string {
  switch (mark.m) {
    case 'glyphs':
      return `g${mark.italic ? 'i' : 'u'}${mark.text}`;
    case 'rule':
      return 'rule';
    case 'paren':
      return mark.open ? '(' : ')';
    case 'corner':
      return (mark.floor ? 'floor' : 'ceil') + (mark.open ? '(' : ')');
    case 'radical':
      return 'root';
    case 'hole':
      return 'hole';
  }
}

/** Keys each atom by its mark and the count of that mark before it, so a glyph that stays keeps its key. */
export function keyed(
  atoms: Atom[],
  prefix: string,
  place: (atom: Atom) => Placed = (atom) => ({
    atom,
    frame: atom.frame,
    alpha: 1,
  }),
): Keyed[] {
  const seen = new Map<string, number>();
  return atoms.map((atom) => {
    const base = `${prefix}|${markKey(atom.mark)}`;
    const count = seen.get(base) ?? 0;
    seen.set(base, count + 1);
    return { key: `${base}#${count}`, placed: place(atom) };
  });
}

/** Damped spring with one overshoot, at progress 0 to 1. */
export function eased(progress: number): number {
  return 1 - Math.exp(-7 * progress) * Math.cos(9 * progress);
}

/** A CSS linear() easing sampling `eased`. */
export function morphEasing(samples = 40): string {
  const points = Array.from({ length: samples + 1 }, (_, i) =>
    i === samples ? 1 : Math.round(eased(i / samples) * 10000) / 10000,
  );
  return `linear(${points.join(', ')})`;
}

/** A glyph run grows about its centre on the baseline, a shape about its centre. */
export function grown(placed: Placed, scale: number): Rect {
  const f = placed.frame;
  if (placed.atom.mark.m === 'glyphs')
    return {
      x: f.x + (f.width * (1 - scale)) / 2,
      y: f.y,
      width: f.width * scale,
      height: f.height * scale,
    };
  return {
    x: f.x + (f.width * (1 - scale)) / 2,
    y: f.y + (f.height * (1 - scale)) / 2,
    width: f.width * scale,
    height: f.height * scale,
  };
}
