import type { InputHTMLAttributes, Ref } from 'react';
import { cx } from '../lib/class-names.ts';
import { useRefs } from '../lib/refs.ts';
import { useShownValue } from '../lib/shown-value.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-text-cell.css';

export interface CanonTextCellProps extends Omit<
  InputHTMLAttributes<HTMLInputElement>,
  'value' | 'onChange' | 'type'
> {
  value?: string;
  placeholder?: string;
  /** Called on every edit. */
  onChange?: (value: string) => void;
  ref?: Ref<HTMLInputElement>;
}

/** Text field that meets its row's edges. */
export default function CanonTextCell({
  value,
  placeholder,
  onChange,
  className,
  ref,
  ...rest
}: CanonTextCellProps) {
  const field = useShownValue<HTMLInputElement>(value);
  return (
    <input
      type="text"
      className={cx('canon-text-cell', className)}
      placeholder={placeholder}
      enterKeyHint="done"
      {...rest}
      ref={useRefs(field, ref)}
      onInput={(event) => onChange?.(event.currentTarget.value)}
      onKeyDown={(event) => {
        if (event.key === 'Enter') event.currentTarget.blur();
      }}
    />
  );
}
