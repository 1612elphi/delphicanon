import type { HTMLAttributes, Ref } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-status.css';

export type CanonStatusTone = 'ok' | 'warn' | 'muted';

export interface CanonStatusProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'children'
> {
  text: string;
  tone: CanonStatusTone;
  /** A padded row of its own for a CanonRows. */
  row?: boolean;
  ref?: Ref<HTMLDivElement>;
}

/** A short state word in the colour of its tone: ok, warn or muted. */
export default function CanonStatus({
  text,
  tone,
  row,
  className,
  ...rest
}: CanonStatusProps) {
  return (
    <div
      className={cx(
        'canon-status',
        `canon-status--${tone}`,
        row && 'canon-status--row',
        className,
      )}
      role="status"
      {...rest}
    >
      {text}
    </div>
  );
}
