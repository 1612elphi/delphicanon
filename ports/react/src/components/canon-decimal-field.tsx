import {
  useEffect,
  useRef,
  useState,
  type HTMLAttributes,
  type KeyboardEvent,
  type Ref,
} from 'react';
import CanonStepper from './canon-stepper.tsx';
import {
  formatDecimal,
  parseDecimal,
  roundDecimal,
} from '@canon/lib/number.ts';
import { cx } from '../lib/class-names.ts';
import { useLatest } from '../lib/refs.ts';
import '@canon/styles/tokens.css';

export interface CanonDecimalFieldProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'onChange' | 'children'
> {
  value: number;
  /** Default 0, or no lower bound when `signed`. */
  min?: number;
  max?: number;
  /** Default "s". */
  unit?: string;
  /** Default 0.1. */
  step?: number;
  /** Places kept; default 3. */
  decimals?: number;
  /** Gives a touch keyboard a minus key; the decimal pad has none. */
  signed?: boolean;
  labelledBy?: string;
  label?: string;
  disabled?: boolean;
  onChange?: (value: number) => void;
  ref?: Ref<HTMLDivElement>;
}

/** Typing commits after this pause, or when the field loses focus. */
export const typingPauseMs = 600;

/** A decimal number with step buttons and a unit; seconds by default. */
export default function CanonDecimalField({
  value: valueArg,
  min: minArg,
  max = Infinity,
  unit = 's',
  step: stepSize = 0.1,
  decimals = 3,
  signed,
  labelledBy,
  label,
  disabled,
  onChange,
  className,
  ...rest
}: CanonDecimalFieldProps) {
  const [held, setHeld] = useState<{ value: number; over: number }>();
  const [draft, setDraft] = useState<string>();
  const typing = useRef<number>(undefined);
  const min = minArg ?? (signed ? -Infinity : 0);
  const value = held && held.over === valueArg ? held.value : valueArg;
  const text = draft ?? formatDecimal(value, decimals);

  // returns the value it leaves, so a step after a commit starts from it
  const apply = (raw: number, from = value) => {
    const next = roundDecimal(raw, decimals, min, max);
    if (next === from) return from;
    setHeld({ value: next, over: valueArg });
    onChange?.(next);
    return next;
  };

  const step = (direction: -1 | 1, from = value) => {
    setDraft(undefined);
    apply(from + direction * stepSize, from);
  };

  const commit = () => {
    window.clearTimeout(typing.current);
    const typed = draft === undefined ? undefined : parseDecimal(draft);
    return typed === undefined ? value : apply(typed);
  };
  const latest = useLatest({ commit });

  useEffect(() => () => window.clearTimeout(typing.current), []);

  const key = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Enter') event.currentTarget.blur();
    if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown') return;
    event.preventDefault();
    step(event.key === 'ArrowUp' ? 1 : -1, commit());
  };

  return (
    <CanonStepper
      className={cx('canon-decimal-field', className)}
      onStep={step}
      disabled={disabled}
      {...rest}
    >
      <span className="canon-stepper-value">
        <input
          type="text"
          className="canon-stepper-field canon-decimal-field-input"
          role="spinbutton"
          aria-valuenow={value}
          aria-valuetext={`${text} ${unit}`}
          inputMode={signed ? 'text' : 'decimal'}
          enterKeyHint="done"
          aria-labelledby={labelledBy}
          aria-label={label}
          value={text}
          disabled={disabled}
          onChange={(event) => {
            setDraft(event.target.value);
            window.clearTimeout(typing.current);
            typing.current = window.setTimeout(
              () => latest.current.commit(),
              typingPauseMs,
            );
          }}
          onKeyDown={key}
          onBlur={() => {
            commit();
            setDraft(undefined);
          }}
        />
        <span className="canon-stepper-unit">{unit}</span>
      </span>
    </CanonStepper>
  );
}
