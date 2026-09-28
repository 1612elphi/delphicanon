import {
  useState,
  type CSSProperties,
  type HTMLAttributes,
  type ReactNode,
} from 'react';
import {
  formatColour,
  hex,
  takesBlackInk,
  type ColourFormat,
  type Rgb,
} from '@canon/lib/colour.ts';
import { springEasing } from '@canon/lib/motion.ts';
import { cx } from '../lib/class-names.ts';
import { canonToast } from '../lib/toast-store.ts';
import CanonGrid from './canon-grid.tsx';
import CanonHeading from './canon-heading.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-palette-card.css';

export interface CanonPaletteCardProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'title' | 'onSelect'
> {
  title: string;
  colours: Rgb[];
  /** Height of the swatches in px. */
  height?: number;
  selected?: number;
  onSelect?: (index: number | undefined) => void;
  /** Nearest colour name for a hex, shown on the widened swatch. */
  nameOf?: (hex: string) => string;
  /** The app's colour format settings; the widened swatch shows the first that is not hex. */
  primaryFormat?: ColourFormat;
  secondaryFormat?: ColourFormat;
  /** A choice between palettes, under the heading: a CanonSegmented. */
  picker?: ReactNode;
  /** Flush cells in a bar under the swatches: CanonButtons of kind cell. */
  actions?: ReactNode;
}

/** Width of the widened swatch against the others. */
export const widened = 3;
const spring = springEasing(0.82);

/**
 * A palette as swatches meeting at hairlines, under a heading. A tap widens
 * a swatch to show its name and values; a tap on the widened swatch copies
 * its hex.
 */
export default function CanonPaletteCard({
  title,
  colours,
  height,
  selected: chosen,
  onSelect,
  nameOf,
  primaryFormat,
  secondaryFormat,
  picker,
  actions,
  className,
  ...rest
}: CanonPaletteCardProps) {
  // a pick holds until the selected prop changes
  const [picked, setPicked] = useState<{
    index: number;
    over: number | undefined;
  }>();
  const index = picked && picked.over === chosen ? picked.index : chosen;
  const selected =
    index !== undefined && index < colours.length ? index : undefined;
  const detailFormat: ColourFormat =
    [primaryFormat ?? 'hex', secondaryFormat ?? 'rgb'].find(
      (format) => format !== 'hex',
    ) ?? 'oklch';

  const tap = (index: number, code: string) => {
    if (index === selected) {
      void canonToast.copy(code);
      return;
    }
    setPicked({ index, over: chosen });
    onSelect?.(index);
  };

  return (
    <div className={cx('canon-palette-card', className)} {...rest}>
      <CanonHeading text={title} />
      {picker}
      <div
        className="canon-palette-card-strip"
        style={
          {
            blockSize: `${height ?? 156}px`,
            '--canon-palette-spring': spring,
          } as CSSProperties
        }
      >
        {colours.map((colour, index) => {
          const code = hex(colour);
          const wide = index === selected;
          return (
            <button
              key={index}
              type="button"
              className={cx(
                'canon-palette-card-swatch',
                wide && 'canon-palette-card-swatch--wide',
              )}
              style={{
                background: code,
                color: takesBlackInk(colour) ? 'black' : 'white',
                flexGrow: wide ? widened : 1,
              }}
              aria-label={nameOf?.(code) ?? code}
              aria-pressed={wide ? 'true' : 'false'}
              onClick={() => tap(index, code)}
            >
              <span className="canon-palette-card-name">
                {wide ? nameOf?.(code) : undefined}
              </span>
              <span className="canon-palette-card-details">
                {formatColour(colour, detailFormat)}
              </span>
              <span className="canon-palette-card-hex">{code}</span>
            </button>
          );
        })}
      </div>
      {actions !== undefined && actions !== null && (
        <CanonGrid>{actions}</CanonGrid>
      )}
    </div>
  );
}
