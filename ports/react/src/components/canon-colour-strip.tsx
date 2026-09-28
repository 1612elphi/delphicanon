import type { HTMLAttributes } from 'react';
import {
  formatColour,
  hex,
  type ColourFormat,
  type Rgb,
} from '@canon/lib/colour.ts';
import { cx } from '../lib/class-names.ts';
import { press } from '../lib/press.ts';
import { canonToast } from '../lib/toast-store.ts';
import CanonSwatch from './canon-swatch.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-colour-strip.css';

export interface CanonColourStripProps extends HTMLAttributes<HTMLDivElement> {
  colour: Rgb;
  /** Shows these colours as swatches instead, each copying its hex on a tap. */
  palette?: Rgb[];
  /** Nearest colour name for a hex. */
  nameOf?: (hex: string) => string;
  /** The value shown and copied; default hex. */
  format?: ColourFormat;
}

/**
 * A strip along the bottom of a colour picture: swatch, nearest name, the
 * colour in the primary format; a tap copies the value. Place it under the
 * picture inside the same canvas.
 */
export default function CanonColourStrip({
  colour,
  palette,
  nameOf,
  format,
  className,
  ...rest
}: CanonColourStripProps) {
  const value = formatColour(colour, format ?? 'hex');
  const name = nameOf?.(hex(colour));
  return (
    <div className={cx('canon-colour-strip', className)} {...rest}>
      {palette && palette.length > 0 ? (
        <div className="canon-colour-strip-palette">
          {palette.map((swatch, index) => (
            <CanonSwatch key={index} colour={swatch} nameOf={nameOf} />
          ))}
        </div>
      ) : (
        <button
          type="button"
          className="canon-colour-strip-single"
          aria-label={`${name ?? ''} ${value}`}
          onClick={() => void canonToast.copy(value)}
          ref={press}
        >
          <span
            className="canon-colour-strip-swatch"
            style={{ background: hex(colour) }}
          />
          <span className="canon-colour-strip-text">
            {name && <span className="canon-colour-strip-name">{name}</span>}
            <span className="canon-colour-strip-value">{value}</span>
          </span>
        </button>
      )}
    </div>
  );
}
