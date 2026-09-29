/** Index of the last heading whose top is at or above `top`, else 0. */
export function litIndex(tops: number[], top: number): number {
  let lit = 0;
  tops.forEach((y, index) => {
    if (y <= top + 1) lit = index;
  });
  return lit;
}

/** Columns of the jump grid for a window `width` px wide. */
export function jumpColumns(width: number): number {
  return width >= 560 ? 3 : 2;
}

/** Delay in ms before tile `index` appears; a long list starts at the lit tile. */
export function appearDelay(index: number, count: number, current = 0): number {
  const origin = count > 30 ? current : 0;
  return 30 * Math.min(Math.abs(index - origin), 24);
}
