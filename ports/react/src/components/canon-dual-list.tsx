import {
  useId,
  useState,
  type CSSProperties,
  type HTMLAttributes,
  type Ref,
} from 'react';
import CanonButton from './canon-button.tsx';
import CanonGrid from './canon-grid.tsx';
import CanonHeading from './canon-heading.tsx';
import { cx } from '../lib/class-names.ts';
import { press } from '../lib/press.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-dual-list.css';

export interface CanonDualItem {
  id: string;
  name: string;
  caption?: string;
}

type Side = 'left' | 'right';

export interface CanonDualListProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'children'
> {
  left: CanonDualItem[];
  right: CanonDualItem[];
  leftTitle: string;
  rightTitle: string;
  /** Height of each list in px; default 240. */
  listHeight?: number;
  onMoveRight?: (id: string) => void;
  onMoveLeft?: (id: string) => void;
  /** Item id and a delta of -1 or 1. */
  onReorder?: (id: string, delta: -1 | 1) => void;
  ref?: Ref<HTMLDivElement>;
}

/** Two columns with one selection between them; the right column can be reordered. */
export default function CanonDualList({
  left,
  right,
  leftTitle,
  rightTitle,
  listHeight = 240,
  onMoveRight,
  onMoveLeft,
  onReorder,
  className,
  style,
  ...rest
}: CanonDualListProps) {
  const [picked, setPicked] = useState<{ side: Side; id: string }>();
  const id = useId();

  // the pick, while its item is still on that side
  const selection =
    picked &&
    (picked.side === 'left' ? left : right).some(
      (item) => item.id === picked.id,
    )
      ? picked
      : undefined;
  const rightIndex =
    selection?.side === 'right'
      ? right.findIndex((item) => item.id === selection.id)
      : -1;

  const move = (side: Side) => {
    if (selection?.side !== side) return;
    setPicked({ side: side === 'left' ? 'right' : 'left', id: selection.id });
    (side === 'left' ? onMoveRight : onMoveLeft)?.(selection.id);
  };

  const reorder = (delta: -1 | 1) => {
    if (selection?.side === 'right') onReorder?.(selection.id, delta);
  };

  const columns: [Side, CanonDualItem[], string][] = [
    ['left', left, leftTitle],
    ['right', right, rightTitle],
  ];

  return (
    <div
      className={cx('canon-dual-list', className)}
      style={
        {
          '--canon-dual-list-height': `${listHeight}px`,
          ...style,
        } as CSSProperties
      }
      {...rest}
    >
      <div className="canon-dual-list-columns">
        {columns.map(([side, items, title], index) => (
          <div className="canon-dual-list-column" key={side}>
            <CanonHeading id={`${id}-${index}`} text={title} />
            <div
              className="canon-dual-list-items"
              role="group"
              aria-labelledby={`${id}-${index}`}
            >
              {items.map((item) => {
                const selected =
                  selection?.side === side && selection.id === item.id;
                return (
                  <button
                    key={item.id}
                    type="button"
                    className={cx(
                      'canon-dual-list-item',
                      selected && 'canon-dual-list-item--selected',
                    )}
                    aria-pressed={selected}
                    ref={press}
                    onClick={() => setPicked({ side, id: item.id })}
                  >
                    <span className="canon-dual-list-name">{item.name}</span>
                    {item.caption && (
                      <span className="canon-dual-list-caption">
                        {item.caption}
                      </span>
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        ))}
      </div>
      <CanonGrid>
        <CanonButton
          kind="cell"
          text="Show"
          disabled={selection?.side !== 'left'}
          onClick={() => move('left')}
        />
        <CanonButton
          kind="cell"
          text="Hide"
          disabled={selection?.side !== 'right'}
          onClick={() => move('right')}
        />
        <CanonButton
          kind="cell"
          text="Up"
          disabled={rightIndex < 1}
          onClick={() => reorder(-1)}
        />
        <CanonButton
          kind="cell"
          text="Down"
          disabled={rightIndex < 0 || rightIndex >= right.length - 1}
          onClick={() => reorder(1)}
        />
      </CanonGrid>
    </div>
  );
}
