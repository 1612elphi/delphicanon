import type { HTMLAttributes, ReactNode, Ref } from 'react';
import CanonButton from './canon-button.tsx';
import { cx } from '../lib/class-names.ts';
import { Minus, Plus } from '../lib/control-icons.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-stepper.css';

export interface CanonStepperProps extends HTMLAttributes<HTMLDivElement> {
  /** Called with -1 or 1; repeats while a button is held. */
  onStep: (direction: -1 | 1) => void;
  disabled?: boolean;
  /** The middle cell, usually a field and its unit. A click anywhere in it focuses the field. */
  children?: ReactNode;
  ref?: Ref<HTMLDivElement>;
}

/** Minus and plus cells either side of a field's cell, divided by hairlines. */
export default function CanonStepper({
  onStep,
  disabled,
  children,
  className,
  ...rest
}: CanonStepperProps) {
  return (
    <div className={cx('canon-stepper', className)} {...rest}>
      <CanonButton
        className="canon-stepper-minus"
        kind="cell"
        icon={<Minus />}
        label="Decrease"
        repeats
        disabled={disabled}
        onClick={() => onStep(-1)}
      />
      <label className="canon-stepper-centre">{children}</label>
      <CanonButton
        className="canon-stepper-plus"
        kind="cell"
        icon={<Plus />}
        label="Increase"
        repeats
        disabled={disabled}
        onClick={() => onStep(1)}
      />
    </div>
  );
}
