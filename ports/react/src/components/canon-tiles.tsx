import { useCallback, useState, type HTMLAttributes, type Ref } from 'react';
import { cx } from '../lib/class-names.ts';
import { useRefs } from '../lib/refs.ts';
import CanonBar from './canon-bar.tsx';
import CanonGrid from './canon-grid.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-tiles.css';

export interface CanonTile {
  label: string;
  value: string;
  /** Share of a level bar along the tile's bottom edge, 0 to 1; none draws no bar. */
  level?: number;
}

export interface CanonTilesProps extends HTMLAttributes<HTMLDivElement> {
  items: CanonTile[];
  ref?: Ref<HTMLDivElement>;
}

/** Least width of a tile; the grid never goes below two columns. */
export const tileWidth = 168;

/**
 * Read-only values as a hairline grid of tiles, label over value. As many
 * columns as fit; a short last row stretches its last tile.
 */
export default function CanonTiles({
  items,
  className,
  ref,
  ...rest
}: CanonTilesProps) {
  const [columns, setColumns] = useState(2);

  const measure = useCallback((element: HTMLDivElement) => {
    let frame = 0;
    // a new column count changes the height; set it next frame, outside this observation
    const observer = new ResizeObserver(([entry]) => {
      const width = entry?.contentRect.width ?? 0;
      const next = Math.max(2, Math.floor(width / tileWidth));
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => setColumns(next));
    });
    observer.observe(element);
    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
    };
  }, []);

  return (
    <div
      className={cx('canon-tiles', className)}
      ref={useRefs(measure, ref)}
      {...rest}
    >
      <CanonGrid columns={columns}>
        {items.map((item, i) => (
          <div className="canon-tiles-tile" key={i}>
            <span className="canon-tiles-label">{item.label}</span>
            <span className="canon-tiles-value">{item.value}</span>
            {item.level !== undefined && (
              <CanonBar className="canon-tiles-level" share={item.level} />
            )}
          </div>
        ))}
      </CanonGrid>
    </div>
  );
}
