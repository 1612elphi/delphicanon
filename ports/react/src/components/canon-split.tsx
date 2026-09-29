import {
  useCallback,
  type CSSProperties,
  type HTMLAttributes,
  type ReactNode,
  type Ref,
} from 'react';
import { cx } from '../lib/class-names.ts';
import { useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-page.css';
import '@canon/components/canon-split.css';

export interface CanonSplitProps extends HTMLAttributes<HTMLDivElement> {
  /** Never splits: the sections stack at every width, sidebar first. */
  oneColumn?: boolean;
  /** Sidebar width in px beside the main pane, at most 40 % of the split. Default 340. */
  sidebarWidth?: number;
  /** In one column the banner stays at the top and the page scrolls under it. */
  bannerSticks?: boolean;
  /** In one column the main sections come before the sidebar's. */
  mainLeadsStacked?: boolean;
  /** Side by side the panes are equal; a sidebar of one canvas fills its pane. */
  halves?: boolean;
  /** In one column the picture shrinks as the page scrolls, down to this band height in px. */
  collapsesTo?: number;
  /** Beside or above a crease, a halves picture runs into the crease band up to the rule. */
  pictureMeetsCrease?: boolean;
  footerHidden?: boolean;
  sidebar?: ReactNode;
  main?: ReactNode;
  /** A CanonCanvas across every column, above the panes. */
  banner?: ReactNode;
  /** A framed strip floating over the bottom of the main pane. */
  footer?: ReactNode;
  ref?: Ref<HTMLDivElement>;
}

/** Share of the height a collapsing picture takes before it shrinks. */
export const collapseLimit = 0.6;

function naturalHeight(canvas: HTMLElement, width: number): number {
  const fixed = Number(canvas.dataset['canonHeight']);
  if (fixed) return fixed;
  const aspect = Number(canvas.dataset['canonAspect']) || 1;
  const frame = parseFloat(
    getComputedStyle(canvas).getPropertyValue('--canon-frame'),
  );
  return width / aspect + (frame || 0) * 2;
}

function collapse(split: HTMLElement, collapsesTo: number) {
  const body = split.querySelector<HTMLElement>(':scope > .canon-split-body');
  if (!body) return;
  const update = () => {
    const stacked =
      getComputedStyle(body).getPropertyValue('--canon-split-layout').trim() !==
      'wide';
    const picture = split.querySelector<HTMLElement>(
      ':scope > .canon-split-body > .canon-split-banner .canon-canvas, .canon-split--halves > .canon-split-body > .canon-split-sidebar > .canon-canvas:only-child',
    );
    split.toggleAttribute('data-collapsing', stacked && !!picture);
    if (!stacked || !picture) return;
    const full = Math.min(
      naturalHeight(picture, split.clientWidth),
      split.clientHeight * collapseLimit,
    );
    // stretches when pulled down
    const band = Math.max(Math.min(collapsesTo, full), full - body.scrollTop);
    split.style.setProperty('--canon-split-full', `${full}px`);
    split.style.setProperty('--canon-split-band', `${band}px`);
  };
  update();
  body.addEventListener('scroll', update, { passive: true });
  const size = new ResizeObserver(update);
  size.observe(split);
  const shape = new MutationObserver(update);
  shape.observe(body, {
    subtree: true,
    attributeFilter: ['data-canon-aspect', 'data-canon-height'],
  });
  return () => {
    body.removeEventListener('scroll', update);
    size.disconnect();
    shape.disconnect();
  };
}

/**
 * Sidebar beside a main pane. Wide: a fixed sidebar on the leading side.
 * Narrower than 640 px or portrait: one column, sidebar first. On a
 * dual-screen device the panes meet at the crease. Sections that are a
 * CanonCanvas span their column; the rest keep the panel padding. The split
 * fills its parent's height.
 */
export default function CanonSplit({
  oneColumn,
  sidebarWidth,
  bannerSticks,
  mainLeadsStacked,
  halves,
  collapsesTo,
  pictureMeetsCrease,
  footerHidden,
  sidebar,
  main,
  banner,
  footer,
  className,
  style,
  ref,
  ...rest
}: CanonSplitProps) {
  const collapsing = useCallback(
    (split: HTMLDivElement) =>
      collapsesTo === undefined ? undefined : collapse(split, collapsesTo),
    [collapsesTo],
  );
  const width =
    sidebarWidth === undefined
      ? undefined
      : { '--canon-split-sidebar': `${sidebarWidth}px` };
  return (
    <div
      className={cx(
        'canon-split',
        halves && 'canon-split--halves',
        bannerSticks && 'canon-split--sticks',
        mainLeadsStacked && 'canon-split--main-leads',
        pictureMeetsCrease && 'canon-split--meets-crease',
        oneColumn && 'canon-split--one-column',
        className,
      )}
      style={{ ...width, ...style } as CSSProperties}
      ref={useRefs(collapsing, ref)}
      {...rest}
    >
      <div className="canon-split-body">
        {banner !== undefined && (
          <div className="canon-split-banner">{banner}</div>
        )}
        {sidebar !== undefined && (
          <div className="canon-split-pane canon-split-sidebar canon-page">
            {sidebar}
          </div>
        )}
        <div className="canon-split-rule" />
        <div className="canon-split-pane canon-split-main canon-page">
          {main}
          {footer !== undefined && !footerHidden && (
            <div className="canon-split-footer">{footer}</div>
          )}
        </div>
      </div>
    </div>
  );
}
