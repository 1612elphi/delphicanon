import type { HTMLAttributes } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-empty-row.css';

export interface CanonEmptyRowProps extends HTMLAttributes<HTMLDivElement> {
  text: string;
}

export default function CanonEmptyRow({
  text,
  className,
  ...rest
}: CanonEmptyRowProps) {
  return (
    <div className={cx('canon-empty-row', className)} {...rest}>
      {text}
    </div>
  );
}
