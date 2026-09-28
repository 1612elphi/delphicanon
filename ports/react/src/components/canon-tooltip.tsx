import {
  useCallback,
  useId,
  type HTMLAttributes,
  type ReactNode,
  type RefCallback,
} from 'react';
import {
  attach,
  hide,
  isOpen,
  panelFor,
  type CanonPlacement,
} from '@canon/lib/popover.ts';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-popover.css';
import '@canon/components/canon-tooltip.css';

export interface CanonTooltipProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'children'
> {
  text: string;
  /** Default top. */
  placement?: CanonPlacement;
  /** Put `trigger` as the ref of the element the hint describes. */
  children: (tip: { trigger: RefCallback<HTMLElement> }) => ReactNode;
}

/** The pointer may cross the gap onto the hint in this many ms before it hides. */
export const tooltipGraceMs = 100;

function describe(element: Element, id: string, on: boolean) {
  const ids = (element.getAttribute('aria-describedby') ?? '')
    .split(/\s+/)
    .filter((other) => other && other !== id);
  if (on) ids.push(id);
  if (ids.length) element.setAttribute('aria-describedby', ids.join(' '));
  else element.removeAttribute('aria-describedby');
}

function setup(element: HTMLElement, id: string, placement: CanonPlacement) {
  const tip = panelFor(element, id);
  const detach = attach(tip, element, { placement });
  describe(element, id, true);
  let leaving: number | undefined;

  const show = () => {
    window.clearTimeout(leaving);
    if (!isOpen(tip)) tip.showPopover();
  };
  const hideNow = () => {
    window.clearTimeout(leaving);
    hide(tip);
  };
  const hideSoon = () => {
    window.clearTimeout(leaving);
    leaving = window.setTimeout(() => hide(tip), tooltipGraceMs);
  };
  const enter = (event: PointerEvent) => {
    if (event.pointerType !== 'touch') show();
  };
  // a click focuses the trigger without :focus-visible, and should not bring the hint back
  const focus = () => {
    if (element.matches(':focus-visible')) show();
  };
  const escape = (event: KeyboardEvent) => {
    if (event.key === 'Escape' && isOpen(tip)) hideNow();
  };

  const listeners = [
    [element, 'pointerenter', enter],
    [element, 'pointerleave', hideSoon],
    [element, 'pointerdown', hideNow],
    [element, 'focusin', focus],
    [element, 'focusout', hideNow],
    [tip, 'pointerenter', show],
    [tip, 'pointerleave', hideSoon],
    [document, 'keydown', escape],
  ] as const;
  for (const [target, type, listener] of listeners)
    target.addEventListener(type, listener as EventListener);
  return () => {
    window.clearTimeout(leaving);
    for (const [target, type, listener] of listeners)
      target.removeEventListener(type, listener as EventListener);
    describe(element, id, false);
    detach();
  };
}

/**
 * A hint shown while the pointer is over the trigger or keyboard focus is
 * on it. Escape and a press hide it.
 */
export default function CanonTooltip({
  text,
  placement = 'top',
  children,
  className,
  ...rest
}: CanonTooltipProps) {
  const id = `${useId()}-tooltip`;
  const trigger = useCallback(
    (element: HTMLElement) => setup(element, id, placement),
    [id, placement],
  );
  return (
    <>
      {children({ trigger })}
      <div
        id={id}
        className={cx('canon-popover canon-tooltip', className)}
        popover="manual"
        role="tooltip"
        {...rest}
      >
        {text}
      </div>
    </>
  );
}
