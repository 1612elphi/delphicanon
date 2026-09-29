import {
  useRef,
  useState,
  type HTMLAttributes,
  type MouseEvent,
  type Ref,
} from 'react';
import { litIndex } from '@canon/lib/jump.ts';
import { reducedMotion } from '@canon/lib/motion.ts';
import CanonJumpGrid, { type CanonJumpSection } from './canon-jump-grid.tsx';
import { press } from '../lib/press.ts';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-heading.css';
import '@canon/components/canon-jump-heading.css';

export interface CanonJumpHeadingProps extends HTMLAttributes<HTMLHeadingElement> {
  text: string;
  /** Under the group's title in the jump grid: its item count. */
  detail?: string;
  ref?: Ref<HTMLHeadingElement>;
}

function scroller(element: HTMLElement): HTMLElement {
  for (let at = element.parentElement; at; at = at.parentElement) {
    const style = getComputedStyle(at);
    // a display: contents pane has no box of its own
    if (style.display !== 'contents' && /auto|scroll/.test(style.overflowY))
      return at;
  }
  return document.documentElement;
}

/**
 * A CanonHeading with a chevron that opens a CanonJumpGrid of every jump
 * heading in the same scrolling box, lit at the group in view; a pick
 * scrolls that heading to the top and focuses it.
 */
export default function CanonJumpHeading({
  text,
  detail,
  className,
  ...rest
}: CanonJumpHeadingProps) {
  const [jump, setJump] = useState<{
    sections: CanonJumpSection[];
    current: number;
  }>();
  const headings = useRef<HTMLElement[]>([]);

  const show = (event: MouseEvent<HTMLButtonElement>) => {
    const heading = event.currentTarget.closest<HTMLElement>(
      '.canon-jump-heading',
    )!;
    const box = scroller(heading);
    const top =
      box === document.documentElement ? 0 : box.getBoundingClientRect().top;
    headings.current = [
      ...box.querySelectorAll<HTMLElement>('.canon-jump-heading'),
    ];
    setJump({
      current: litIndex(
        headings.current.map((h) => h.getBoundingClientRect().top),
        top,
      ),
      sections: headings.current.map((h) => ({
        title: h.dataset['canonJumpTitle'] ?? '',
        detail: h.dataset['canonJumpDetail'],
      })),
    });
  };

  const pick = (index: number) => {
    const target = headings.current[index];
    if (!target?.isConnected) return;
    target.scrollIntoView({
      block: 'start',
      behavior: reducedMotion() ? 'instant' : 'smooth',
    });
    target.querySelector('button')?.focus({ preventScroll: true });
  };

  return (
    <>
      <h3
        className={cx('canon-heading canon-jump-heading', className)}
        data-canon-jump-title={text}
        data-canon-jump-detail={detail}
        {...rest}
      >
        <button
          type="button"
          className="canon-jump-heading-button"
          aria-haspopup="dialog"
          aria-expanded={jump ? 'true' : 'false'}
          ref={press}
          onClick={show}
        >
          {text}
          <span className="canon-jump-heading-chevron" aria-hidden="true">
            ›
          </span>
        </button>
      </h3>
      {jump && (
        <CanonJumpGrid
          open
          sections={jump.sections}
          current={jump.current}
          onPick={pick}
          onClose={() => setJump(undefined)}
        />
      )}
    </>
  );
}
