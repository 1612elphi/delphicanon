import type { CSSProperties, HTMLAttributes } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-page.css';

export interface CanonPageProps extends HTMLAttributes<HTMLDivElement> {
  /** Widest a section gets, in px; null for no cap. Default 720. */
  maxWidth?: number | null;
}

/**
 * Scrolling tool body. Sections are centred, capped at maxWidth and inset by
 * the panel padding; a CanonCanvas section spans the full width instead
 * (CanonPage and CanonPaddedSection).
 */
export default function CanonPage({
  maxWidth,
  className,
  style,
  children,
  ...rest
}: CanonPageProps) {
  const width =
    maxWidth === null
      ? undefined
      : { '--canon-page-max-width': `${maxWidth ?? 720}px` };
  return (
    <div
      className={cx('canon-page', className)}
      style={{ ...width, ...style } as CSSProperties}
      {...rest}
    >
      {children}
    </div>
  );
}
