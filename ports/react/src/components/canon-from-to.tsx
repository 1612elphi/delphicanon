import type { HTMLAttributes, Ref } from 'react';
import CanonMenuCell from './canon-menu-cell.tsx';
import { cx } from '../lib/class-names.ts';
import { ArrowRight } from '../lib/control-icons.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-from-to.css';

export interface CanonFromToProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'children'
> {
  items: string[];
  from?: number;
  to?: number;
  /** Accessible names of the two menus; default From and To. */
  fromLabel?: string;
  toLabel?: string;
  disabled?: boolean;
  onFromChange?: (index: number) => void;
  onToChange?: (index: number) => void;
  ref?: Ref<HTMLDivElement>;
}

/** Two menus of the same choices with an arrow between: a conversion from one to the other. */
export default function CanonFromTo({
  items,
  from,
  to,
  fromLabel,
  toLabel,
  disabled,
  onFromChange,
  onToChange,
  className,
  ...rest
}: CanonFromToProps) {
  return (
    <div className={cx('canon-from-to', className)} role="group" {...rest}>
      <CanonMenuCell
        items={items}
        selected={from}
        label={fromLabel || 'From'}
        disabled={disabled}
        onChange={onFromChange}
      />
      <span className="canon-from-to-arrow" aria-hidden="true">
        <ArrowRight />
      </span>
      <CanonMenuCell
        items={items}
        selected={to}
        label={toLabel || 'To'}
        disabled={disabled}
        onChange={onToChange}
      />
    </div>
  );
}
