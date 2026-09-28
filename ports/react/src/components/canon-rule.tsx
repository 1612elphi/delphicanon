import type { HTMLAttributes } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-rule.css';

export interface CanonRuleProps extends HTMLAttributes<HTMLDivElement> {
  vertical?: boolean;
}

export default function CanonRule({
  vertical,
  className,
  ...rest
}: CanonRuleProps) {
  return (
    <div
      className={cx(
        'canon-rule',
        vertical && 'canon-rule--vertical',
        className,
      )}
      role="separator"
      aria-orientation={vertical ? 'vertical' : 'horizontal'}
      {...rest}
    />
  );
}
