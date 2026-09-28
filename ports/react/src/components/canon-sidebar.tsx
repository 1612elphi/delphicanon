import type { HTMLAttributes, ReactNode } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-sidebar.css';

export interface CanonSidebarProps extends HTMLAttributes<HTMLElement> {
  /**
   * true: the icon rail. false: full width at every size. Unset: the rail
   * inside a `canon-window` container narrower than 640 px.
   */
  collapsed?: boolean;
  /** A picture above the rows that does not scroll with them. */
  hero?: ReactNode;
  /** CanonSidebarRows, and CanonHeadings between groups. */
  children?: ReactNode;
}

function state(collapsed: boolean | undefined) {
  if (collapsed === true) return 'canon-sidebar--collapsed';
  if (collapsed === false) return 'canon-sidebar--expanded';
  return undefined;
}

/**
 * The window's navigation column (Sidebar): 240 px of 44 px rows on the
 * muted background, the gaps between rows and cells showing the border
 * colour, a frame-width rule on the trailing edge.
 */
export default function CanonSidebar({
  collapsed,
  hero,
  children,
  className,
  ...rest
}: CanonSidebarProps) {
  return (
    <nav className={cx('canon-sidebar', state(collapsed), className)} {...rest}>
      {hero !== undefined && hero !== null && (
        <div className="canon-sidebar-hero">{hero}</div>
      )}
      <div className="canon-sidebar-scroll">
        <div className="canon-sidebar-rows">{children}</div>
      </div>
    </nav>
  );
}
