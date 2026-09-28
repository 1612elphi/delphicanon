import { useState, type CSSProperties, type HTMLAttributes } from 'react';
import { hasDigits, hundredths, timecodeRuns } from '@canon/lib/timecode.ts';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-timecode.css';

export interface CanonTimecodeProps extends HTMLAttributes<HTMLSpanElement> {
  /** Seconds to show; none shows hyphens. Ignored when `text` is set. */
  seconds?: number | null;
  /**
   * A timecode already formatted. One without digits, or null, shows
   * hyphens in the shape of the last one.
   */
  text?: string | null;
  /** Replaces minutes, seconds and hundredths, for SMPTE timecode. */
  format?: (seconds: number) => string;
  /** Font size in px; default 44. */
  size?: number;
  /** CSS colour of the halo that keeps the digits clear of what runs under them; default the muted colour. */
  halo?: string;
  /** What the counter measures, for assistive technology. */
  label?: string;
}

/**
 * FluoWrite's full stop is 8.2 units wide against the colon's 21.8, and the
 * digits have no side bearing; padding either side seats it in a slot a
 * little wider than a colon's.
 */
export const stopPadding = ((21.8 - 8.2) / 2 + 4) / 100;

/**
 * Counter in the segment font, for the corner of a waveform band. Leading
 * zeros that carry no value are dimmed.
 */
export default function CanonTimecode({
  seconds,
  text,
  format,
  size = 44,
  halo,
  label,
  className,
  style,
  ...rest
}: CanonTimecodeProps) {
  const next = text === undefined ? (format ?? hundredths)(seconds ?? 0) : text;
  const blank =
    text === undefined
      ? seconds === undefined || seconds === null
      : !hasDigits(text);
  // a null text keeps the last shape, as hyphens
  const [last, setLast] = useState(() => hundredths(0));
  if (next && next !== last) setLast(next);
  const runs = timecodeRuns(next || last, blank);
  const spoken = blank ? undefined : runs.map((run) => run.text).join('');

  const vars: Record<string, string> = {
    '--canon-timecode-size': `${size}px`,
    '--canon-timecode-stop': `${stopPadding * size}px`,
  };
  if (halo) vars['--canon-timecode-halo'] = halo;

  return (
    <span
      className={cx('canon-timecode', className)}
      style={{ ...vars, ...style } as CSSProperties}
      role="timer"
      aria-label={label}
      {...rest}
    >
      <span className="canon-timecode-halo" aria-hidden="true">
        {runs.map((run, i) => (
          <span
            key={i}
            className={run.stop ? 'canon-timecode-stop' : undefined}
          >
            {run.text}
          </span>
        ))}
      </span>
      <span className="canon-timecode-digits" aria-hidden="true">
        {runs.map((run, i) => (
          <span
            key={i}
            className={
              cx(
                run.stop && 'canon-timecode-stop',
                run.dim && 'canon-timecode-dim',
              ) || undefined
            }
          >
            {run.text}
          </span>
        ))}
      </span>
      {spoken && <span className="canon-timecode-spoken">{spoken}</span>}
    </span>
  );
}
