/** Tile side and symbol size of the banner pattern (CanonPattern), in px. */
export const patternTile = { side: 92, symbol: 24 } as const;

/**
 * A CSS url() for `--canon-pattern`: the symbol twice on the diagonal of a
 * 92 px tile. Canvases with a pattern use it as a mask, so the symbol's
 * colours do not matter, only its shape.
 */
export function canonPatternTile(symbolSvg: string): string {
  const { side, symbol } = patternTile;
  const href = `data:image/svg+xml,${encodeURIComponent(symbolSvg)}`;
  const at = (centre: number) =>
    `<image href="${href}" x="${centre - symbol / 2}" y="${centre - symbol / 2}" width="${symbol}" height="${symbol}"/>`;
  const tile = `<svg xmlns="http://www.w3.org/2000/svg" width="${side}" height="${side}">${at(side * 0.25)}${at(side * 0.75)}</svg>`;
  return `url("data:image/svg+xml,${encodeURIComponent(tile)}")`;
}
