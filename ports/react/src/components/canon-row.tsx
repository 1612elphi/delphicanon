import { useId, type HTMLAttributes, type ReactNode } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-row.css';

export type CanonRowForm = 'plain' | 'flush' | 'stacked';

export interface CanonRowProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'title' | 'children'
> {
  title: string;
  detail?: string;
  /** Shown before the title in a plain row. */
  icon?: ReactNode;
  /**
   * plain: the control keeps air around it. flush: the control meets the
   * row's top, bottom and trailing edge behind a hairline. stacked: the
   * control spans the row below the label.
   */
  form?: CanonRowForm;
  /** Longest title among sibling rows, so a grid of rows stacks as one. */
  sizingTitle?: string;
  /** The control; a function gets the title's id for aria-labelledby. */
  children?: ReactNode | ((titleId: string) => ReactNode);
}

/**
 * Label beside a control. A row too narrow for both puts the control below
 * the label.
 */
export default function CanonRow({
  title,
  detail,
  icon,
  form = 'plain',
  sizingTitle,
  children,
  className,
  ...rest
}: CanonRowProps) {
  const titleId = `${useId()}-title`;
  const showsIcon = icon !== undefined && form === 'plain';
  return (
    <div className={cx('canon-row', `canon-row--${form}`, className)} {...rest}>
      <div className="canon-row-label">
        {showsIcon && (
          <span className="canon-row-icon" aria-hidden="true">
            {icon}
          </span>
        )}
        <div className="canon-row-text">
          <span className="canon-row-title" id={titleId}>
            {title}
          </span>
          {detail && <span className="canon-row-detail">{detail}</span>}
          {sizingTitle && (
            <span
              className="canon-row-title canon-row-sizer"
              aria-hidden="true"
            >
              {sizingTitle}
            </span>
          )}
        </div>
      </div>
      {children !== undefined && children !== null && (
        <div className="canon-row-control">
          {typeof children === 'function' ? children(titleId) : children}
        </div>
      )}
    </div>
  );
}
