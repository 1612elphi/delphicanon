import type { CSSProperties, HTMLAttributes, Ref } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-loader.css';

export type CanonLoaderMode = 'snake' | 'comet' | 'dot' | 'twin' | 'thinking';

export interface CanonLoaderProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'children'
> {
  /** Default snake. thinking swings back and forth. */
  mode?: CanonLoaderMode;
  /** Runs anticlockwise; thinking ignores it. */
  reverse?: boolean;
  /** Cell side in px; default 8. */
  cell?: number;
  /** Gap between cells in px; default 2. */
  gap?: number;
  ref?: Ref<HTMLDivElement>;
}

const ringCell = (i: number) => (
  <span key={i} style={{ '--i': i } as CSSProperties} />
);

/**
 * 3 x 3 cell loader in the current colour, the web nds-loader: a lit head
 * runs clockwise round the eight outer cells over a lit centre.
 */
export default function CanonLoader({
  mode,
  reverse,
  cell = 8,
  gap = 2,
  className,
  style,
  ...rest
}: CanonLoaderProps) {
  return (
    <div
      className={cx(
        'canon-loader',
        `canon-loader--${mode || 'snake'}`,
        reverse && 'canon-loader--reverse',
        className,
      )}
      role="status"
      aria-label="Loading"
      style={
        {
          '--canon-loader-cell': `${cell}px`,
          '--canon-loader-gap': `${gap}px`,
          ...style,
        } as CSSProperties
      }
      {...rest}
    >
      {[0, 1, 2, 7].map(ringCell)}
      <i />
      {[3, 6, 5, 4].map(ringCell)}
    </div>
  );
}
