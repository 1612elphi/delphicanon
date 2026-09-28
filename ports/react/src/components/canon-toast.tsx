import { useLayoutEffect, useRef, type HTMLAttributes } from 'react';
import { springEasing } from '@canon/lib/motion.ts';
import { placeToast, type Box } from '@canon/lib/toast.ts';
import { cx } from '../lib/class-names.ts';
import { Check } from '../lib/control-icons.tsx';
import { canonToast, useToastState } from '../lib/toast-store.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-toast.css';

export type CanonToastProps = HTMLAttributes<HTMLDivElement>;

const bump = springEasing(0.6);

/** The column a pointer at `target` belongs to, with its bottom above a footer. */
function column(target: Element | null | undefined): Box {
  const pad = 16;
  const split = target?.closest('.canon-split');
  if (!split) {
    return {
      left: 0,
      top: 0,
      right: window.innerWidth,
      bottom: window.innerHeight - pad,
    };
  }
  const pane = target?.closest('.canon-split-pane')?.getBoundingClientRect();
  // one column: panes have no box of their own
  const box = pane && pane.width > 0 ? pane : split.getBoundingClientRect();
  let bottom = box.bottom - pad;
  const footer = split
    .querySelector('.canon-split-footer')
    ?.getBoundingClientRect();
  if (footer && footer.left < box.right && footer.right > box.left) {
    bottom = footer.top - 10;
  }
  return { left: box.left, top: box.top, right: box.right, bottom };
}

/**
 * The toast outlet. Render it once, near the root of the app; `canonToast`
 * from `lib/toast-store.ts` shows it. It fades in, stays 1.4 s after the
 * last show and fades out; a show while visible bumps it.
 */
export default function CanonToast({ className, ...rest }: CanonToastProps) {
  const { shown, visible, detail } = useToastState();
  const outer = useRef<HTMLDivElement>(null);
  const note = useRef<HTMLDivElement>(null);

  // changes on every show, so a screen reader reads each one
  const announcement = visible ? (shown % 2 ? 'Copied' : 'Copied ') : '';

  useLayoutEffect(() => {
    const element = outer.current;
    if (shown === 0 || !element || !note.current) return;
    const still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const showing = element.style.opacity === '1';
    if (!visible) {
      element.style.opacity = '0';
      element.animate(
        [
          { opacity: 1, transform: 'none' },
          { opacity: 0, transform: still ? 'none' : 'translateY(6px)' },
        ],
        { duration: 300, easing: 'ease-in' },
      );
      return;
    }
    const pointer = canonToast.lastPointer;
    const band = column(pointer?.target);
    note.current.style.maxWidth = `${Math.max(0, band.right - band.left - 32)}px`;
    const place = placeToast(band, note.current.offsetHeight, pointer);
    element.style.left = `${place.x}px`;
    element.style.top = `${place.bottom}px`;
    element.style.opacity = '1';
    if (!showing) {
      element.animate(
        [
          { opacity: 0, transform: still ? 'none' : 'translateY(10px)' },
          { opacity: 1, transform: 'none' },
        ],
        { duration: 220, easing: 'ease-out' },
      );
    } else if (!still) {
      element.animate([{ transform: 'scale(1.06)' }, { transform: 'none' }], {
        duration: 350,
        easing: bump,
      });
    }
  }, [shown, visible]);

  return (
    <>
      <div className="canon-toast-live" role="status">
        {announcement}
      </div>
      <div
        className={cx('canon-toast', className)}
        aria-hidden="true"
        ref={outer}
        {...rest}
      >
        <div className="canon-toast-note" ref={note}>
          <span className="canon-toast-check">
            <Check />
          </span>
          <span className="canon-toast-title">Copied</span>
          {detail && <span className="canon-toast-detail">{detail}</span>}
        </div>
      </div>
    </>
  );
}
