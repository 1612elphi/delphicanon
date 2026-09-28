import {
  useState,
  type HTMLAttributes,
  type KeyboardEvent,
  type Ref,
} from 'react';
import CanonStepper from './canon-stepper.tsx';
import { clamp, parseInteger } from '@canon/lib/number.ts';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';

export interface CanonNumberFieldProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'onChange' | 'children'
> {
  value: number;
  min?: number;
  max?: number;
  step?: number;
  /** Muted, after the number. */
  unit?: string;
  /** Id of the element that names the field, such as a row title. */
  labelledBy?: string;
  label?: string;
  disabled?: boolean;
  onChange?: (value: number) => void;
  ref?: Ref<HTMLDivElement>;
}

/** Integer with step buttons either side. Arrow keys step too. */
export default function CanonNumberField({
  value: valueArg,
  min = 0,
  max = Number.MAX_SAFE_INTEGER,
  step = 1,
  unit,
  labelledBy,
  label,
  disabled,
  onChange,
  className,
  ...rest
}: CanonNumberFieldProps) {
  // a change holds until the value prop changes
  const [held, setHeld] = useState<{ value: number; over: number }>();
  const [draft, setDraft] = useState<string>();
  const value = clamp(
    held && held.over === valueArg ? held.value : valueArg,
    min,
    max,
  );
  const text = draft ?? String(value);

  const commit = (next: number) => {
    if (next === value) return;
    setHeld({ value: next, over: valueArg });
    onChange?.(next);
  };

  const nudge = (direction: -1 | 1) => {
    setDraft(undefined);
    commit(clamp(value + direction * step, min, max));
  };

  const key = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Enter') event.currentTarget.blur();
    if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown') return;
    event.preventDefault();
    nudge(event.key === 'ArrowUp' ? 1 : -1);
  };

  return (
    <CanonStepper
      className={cx('canon-number-field', className)}
      onStep={nudge}
      disabled={disabled}
      {...rest}
    >
      <span className="canon-stepper-value">
        <input
          type="text"
          className="canon-stepper-field"
          role="spinbutton"
          aria-valuenow={value}
          aria-valuemin={min}
          aria-valuemax={max}
          inputMode={min < 0 ? 'text' : 'numeric'}
          enterKeyHint="done"
          aria-labelledby={labelledBy}
          aria-label={label}
          value={text}
          disabled={disabled}
          onChange={(event) => {
            const typed = event.target.value;
            setDraft(typed);
            const parsed = parseInteger(typed);
            if (parsed !== undefined && parsed >= min && parsed <= max)
              commit(parsed);
          }}
          onKeyDown={key}
          onBlur={() => setDraft(undefined)}
        />
        {unit && <span className="canon-stepper-unit">{unit}</span>}
      </span>
    </CanonStepper>
  );
}
