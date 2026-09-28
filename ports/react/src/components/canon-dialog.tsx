import {
  useCallback,
  useId,
  useLayoutEffect,
  useRef,
  type HTMLAttributes,
  type ReactNode,
  type Ref,
} from 'react';
import { dialogMotion, reducedMotion } from '@canon/lib/motion.ts';
import CanonGrid from './canon-grid.tsx';
import CanonHeading from './canon-heading.tsx';
import CanonRows from './canon-rows.tsx';
import { cx } from '../lib/class-names.ts';
import { useLatest, useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-dialog.css';

/** Closes with the motion out; `onClose` then gets `returnValue`. */
export type CanonDialogClose = (returnValue?: string) => void;

/** A block: content, or a function of `close`. */
export type CanonDialogBlock =
  ReactNode | ((close: CanonDialogClose) => ReactNode);

export interface CanonDialogProps extends Omit<
  HTMLAttributes<HTMLDialogElement>,
  'title' | 'children'
> {
  /** Opens with `showModal`. The owner sets it back to false in `onClose`; setting it false itself closes at once, without motion. */
  open: boolean;
  /** The heading, and the dialog's accessible name. */
  title?: string;
  /** Text under the heading, and the accessible description. */
  message?: string;
  /** role alertdialog; a click on the backdrop does not close it. */
  alert?: boolean;
  /** Escape and a click on the backdrop close it; default true. */
  dismissable?: boolean;
  /** Every close, with the return value: the argument to `close`, or the value of the button that submitted a `method="dialog"` form. */
  onClose?: (returnValue: string) => void;
  /** Above the message, under the heading: a search field, a row. */
  header?: CanonDialogBlock;
  /** Rows, separated by hairlines; scrolls when the dialog is full. */
  children?: CanonDialogBlock;
  /** Buttons, laid in a CanonGrid. */
  footer?: CanonDialogBlock;
  ref?: Ref<HTMLDialogElement>;
}

export interface CanonDialogBaseProps extends CanonDialogProps {
  /** The classes CanonDialog or CanonSheet puts first. */
  kindClasses: string;
  /** Keyframes of the motion in; played backwards on the way out. */
  keyframes: (dialog: HTMLDialogElement) => Keyframe[];
}

function animate(
  dialog: HTMLDialogElement,
  keyframes: Keyframe[],
  entering: boolean,
): Animation[] {
  const options: KeyframeAnimationOptions = entering
    ? { duration: dialogMotion.inMs, easing: dialogMotion.inEasing }
    : {
        duration: dialogMotion.outMs,
        easing: dialogMotion.outEasing,
        direction: 'reverse',
        fill: 'forwards',
      };
  return [
    dialog.animate(keyframes, options),
    dialog.animate([{ opacity: 0 }, { opacity: 1 }], {
      ...options,
      pseudoElement: '::backdrop',
    }),
  ];
}

const given = (block: CanonDialogBlock) =>
  block !== undefined && block !== null && block !== false;

/** CanonDialog with the classes and motion of its kind; CanonSheet is one. */
export function CanonDialogBase({
  open,
  title,
  message,
  alert,
  dismissable = true,
  onClose,
  header,
  children,
  footer,
  kindClasses,
  keyframes,
  className,
  ref,
  ...rest
}: CanonDialogBaseProps) {
  const id = useId();
  const titleId = `${id}-title`;
  const messageId = `${id}-message`;
  const element = useRef<HTMLDialogElement>(null);
  const invoker = useRef<HTMLElement>(undefined);
  const closing = useRef(false);
  const latest = useLatest({ alert, dismissable, onClose, keyframes });

  const close: CanonDialogClose = useCallback(
    (returnValue = '') => {
      const dialog = element.current;
      if (!dialog?.open || closing.current) return;
      closing.current = true;
      const animations = reducedMotion()
        ? []
        : animate(dialog, latest.current.keyframes(dialog), false);
      const done = () => {
        closing.current = false;
        dialog.close(returnValue);
        // fill would hold next opening
        animations.forEach((animation) => animation.cancel());
      };
      Promise.all(animations.map((animation) => animation.finished)).then(
        done,
        done,
      );
    },
    [latest],
  );

  useLayoutEffect(() => {
    const dialog = element.current;
    if (!dialog) return;
    if (open && !dialog.open) {
      const active = document.activeElement;
      invoker.current = active instanceof HTMLElement ? active : undefined;
      dialog.returnValue = '';
      dialog.showModal();
      if (!reducedMotion())
        animate(dialog, latest.current.keyframes(dialog), true);
    } else if (!open && dialog.open) {
      dialog.close();
    }
  }, [open, latest]);

  const listen = useCallback(
    (dialog: HTMLDialogElement) => {
      const cancel = (event: Event) => {
        event.preventDefault();
        if (latest.current.dismissable) close();
      };
      // press must start outside
      let downOnBackdrop = false;
      const down = (event: PointerEvent) => {
        downOnBackdrop = event.target === dialog;
      };
      const click = (event: MouseEvent) => {
        if (!downOnBackdrop || event.target !== dialog) return;
        if (latest.current.alert || !latest.current.dismissable) return;
        const r = dialog.getBoundingClientRect();
        const inside =
          event.clientX >= r.left &&
          event.clientX <= r.right &&
          event.clientY >= r.top &&
          event.clientY <= r.bottom;
        if (!inside) close();
      };
      const submit = (event: SubmitEvent) => {
        if ((event.target as HTMLFormElement).method !== 'dialog') return;
        event.preventDefault();
        const submitter = event.submitter as HTMLButtonElement | null;
        close(submitter?.value ?? '');
      };
      const closed = () => {
        const returnTo = invoker.current;
        invoker.current = undefined;
        if (returnTo?.isConnected) returnTo.focus();
        latest.current.onClose?.(dialog.returnValue);
      };

      dialog.addEventListener('cancel', cancel);
      dialog.addEventListener('pointerdown', down);
      dialog.addEventListener('click', click);
      dialog.addEventListener('submit', submit);
      dialog.addEventListener('close', closed);
      return () => {
        dialog.removeEventListener('cancel', cancel);
        dialog.removeEventListener('pointerdown', down);
        dialog.removeEventListener('click', click);
        dialog.removeEventListener('submit', submit);
        dialog.removeEventListener('close', closed);
      };
    },
    [latest, close],
  );

  const block = (content: CanonDialogBlock) =>
    typeof content === 'function' ? content(close) : content;
  // close reads its refs only when a block's handler calls it
  /* eslint-disable react-hooks/refs */
  const blocks = open && {
    header: block(header),
    body: block(children),
    footer: block(footer),
  };
  /* eslint-enable react-hooks/refs */

  return (
    <dialog
      className={cx(kindClasses, className)}
      role={alert ? 'alertdialog' : undefined}
      aria-labelledby={title ? titleId : undefined}
      aria-describedby={message ? messageId : undefined}
      ref={useRefs(element, listen, ref)}
      {...rest}
    >
      {blocks && (
        <CanonRows framed className="canon-dialog-rows">
          {title && (
            <CanonHeading
              text={title}
              id={titleId}
              className="canon-dialog-title"
            />
          )}
          {given(header) && (
            <div className="canon-dialog-header">{blocks.header}</div>
          )}
          {message && (
            <p className="canon-dialog-message" id={messageId}>
              {message}
            </p>
          )}
          {given(children) && (
            <div className="canon-dialog-body">{blocks.body}</div>
          )}
          {given(footer) && (
            <CanonGrid className="canon-dialog-footer">
              {blocks.footer}
            </CanonGrid>
          )}
        </CanonRows>
      )}
    </dialog>
  );
}

function grow(): Keyframe[] {
  return [
    { opacity: 0, transform: `scale(${dialogMotion.scale})` },
    { opacity: 1, transform: 'none' },
  ];
}

/**
 * A modal dialog: the platform's `<dialog>` with `showModal`, so the top
 * layer, the focus trap, Escape and `inert` on the page are the browser's.
 * Content renders while `open`; focus returns to the element that had it.
 */
export default function CanonDialog(props: CanonDialogProps) {
  return (
    <CanonDialogBase
      {...props}
      kindClasses={cx('canon-dialog', props.alert && 'canon-dialog--alert')}
      keyframes={grow}
    />
  );
}
