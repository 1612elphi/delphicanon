import { useCallback, type HTMLAttributes } from 'react';
import {
  formatColour,
  hex as hexOf,
  parseHex,
  type ColourFormat,
  type Rgb,
} from '@canon/lib/colour.ts';
import { cx } from '../lib/class-names.ts';
import { press } from '../lib/press.ts';
import { useLatest, useRefs } from '../lib/refs.ts';
import { useShownValue } from '../lib/shown-value.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-colour-well.css';

export interface CanonColourWellProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'onChange'
> {
  /** Caption over the hex, and the swatch's accessible name. */
  label?: string;
  colour: Rgb;
  /** The app's primary colour format, echoed under the hex unless it is hex. */
  format?: ColourFormat;
  onChange?: (colour: Rgb) => void;
}

/** Swatch cell that opens the system picker, beside a hex field. */
export default function CanonColourWell({
  label,
  colour,
  format,
  onChange,
  className,
  ...rest
}: CanonColourWellProps) {
  const hex = hexOf(colour);
  const digits = hex.slice(1);
  const echo =
    format && format !== 'hex' ? formatColour(colour, format) : undefined;
  const field = useShownValue<HTMLInputElement>(digits);
  const latest = useLatest({ hex, digits, onChange });

  // the native change event: the field commits on Return or when it loses focus
  const typed = useCallback(
    (input: HTMLInputElement) => {
      const change = () => {
        const { hex, digits, onChange } = latest.current;
        const typed = input.value.replace(/[^\da-f]/gi, '');
        const colour = typed.length === 6 ? parseHex(typed) : undefined;
        if (colour && hexOf(colour) !== hex) onChange?.(colour);
        input.value = colour ? hexOf(colour).slice(1) : digits;
      };
      input.addEventListener('change', change);
      return () => input.removeEventListener('change', change);
    },
    [latest],
  );

  return (
    <div className={cx('canon-colour-well', className)} {...rest}>
      <div
        className="canon-colour-well-swatch"
        style={{ background: hex }}
        ref={press}
      >
        <input
          type="color"
          value={hex}
          aria-label={label ? label : 'Colour'}
          onChange={(event) => {
            const picked = parseHex(event.target.value);
            if (picked) onChange?.(picked);
          }}
        />
      </div>
      <div className="canon-colour-well-cell">
        {label && <span className="canon-colour-well-label">{label}</span>}
        <span className="canon-colour-well-field">
          <span className="canon-colour-well-hash" aria-hidden="true">
            #
          </span>
          <input
            type="text"
            placeholder="000000"
            maxLength={7}
            spellCheck={false}
            autoComplete="off"
            autoCapitalize="off"
            aria-label={label ? label : 'Hex'}
            onKeyDown={(event) => {
              if (event.key === 'Enter') event.currentTarget.blur();
            }}
            ref={useRefs(field, typed)}
          />
        </span>
        {echo && <span className="canon-colour-well-echo">{echo}</span>}
      </div>
    </div>
  );
}
