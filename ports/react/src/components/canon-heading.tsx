import type { HTMLAttributes } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-heading.css';

export interface CanonHeadingProps extends HTMLAttributes<HTMLHeadingElement> {
  text: string;
}

export default function CanonHeading({
  text,
  className,
  ...rest
}: CanonHeadingProps) {
  return (
    <h3 className={cx('canon-heading', className)} {...rest}>
      {text}
    </h3>
  );
}
