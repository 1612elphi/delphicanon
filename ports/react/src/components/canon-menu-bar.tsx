import {
  useId,
  useMemo,
  useRef,
  useState,
  type HTMLAttributes,
  type KeyboardEvent as ReactKeyboardEvent,
  type PointerEvent as ReactPointerEvent,
  type Ref,
} from 'react';
import { wrap } from '@canon/lib/menu.ts';
import { attach, hide } from '@canon/lib/popover.ts';
import CanonButton from './canon-button.tsx';
import CanonGrid from './canon-grid.tsx';
import {
  CanonMenuList,
  showMenu,
  type CanonMenuEntry,
  type CanonMenuItem,
} from './canon-menu.tsx';
import { cx } from '../lib/class-names.ts';
import { useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-menu-bar.css';

export interface CanonMenuBarMenu {
  title: string;
  items: CanonMenuEntry[];
}

export interface CanonMenuBarProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'onSelect' | 'children'
> {
  menus: CanonMenuBarMenu[];
  /** The item, and the index of the menu it is in. */
  onSelect?: (item: CanonMenuItem, menu: number) => void;
  ref?: Ref<HTMLDivElement>;
}

// Tab out of the bar closes its menu
function closeOnLeave(root: HTMLDivElement) {
  const focusout = (event: FocusEvent) => {
    const next = event.relatedTarget;
    const open = root.querySelector<HTMLElement>(
      ':scope > .canon-menu:popover-open',
    );
    if (open && next instanceof Node && !root.contains(next)) hide(open);
  };
  root.addEventListener('focusout', focusout);
  return () => root.removeEventListener('focusout', focusout);
}

/**
 * A row of flush cells, each opening a menu. While one is open, the
 * pointer over another cell or the inline arrow keys move to its menu, as
 * in the macOS menu bar. Give it an `aria-label`.
 */
export default function CanonMenuBar({
  menus,
  onSelect,
  className,
  ref,
  ...rest
}: CanonMenuBarProps) {
  const id = `${useId()}-bar`;
  /** The cell in the tab order. */
  const [current, setCurrent] = useState(0);
  const [opened, setOpened] = useState<number>();
  const root = useRef<HTMLDivElement>(null);
  const count = menus.length;

  const cell = (index: number) =>
    root.current?.querySelector<HTMLElement>(`[data-menu-cell="${index}"]`);
  const panel = (index: number) =>
    root.current?.querySelector<HTMLElement>(
      `#${CSS.escape(`${id}-${index}`)}`,
    );
  const openPanel = () =>
    root.current?.querySelector<HTMLElement>(
      ':scope > .canon-menu:popover-open',
    );

  const anchors = useMemo(
    () =>
      Array.from({ length: count }, (_, index) => (list: HTMLDivElement) => {
        const button = list.parentElement?.querySelector<HTMLElement>(
          `[data-menu-cell="${index}"]`,
        );
        if (!button) return;
        const detach = attach(list, button, {
          placement: 'bottom-start',
          invokes: true,
          haspopup: 'menu',
        });
        const toggle = (event: ToggleEvent) => {
          const open = event.newState === 'open';
          setOpened((was) => (open ? index : was === index ? undefined : was));
        };
        list.addEventListener('toggle', toggle);
        return () => {
          list.removeEventListener('toggle', toggle);
          detach();
        };
      }),
    [count],
  );

  /** Focus a cell; if a menu is open, the cell's menu replaces it with focus left on the cell. */
  const move = (to: number) => {
    const next = panel(to);
    if (next && openPanel()) showMenu(next, 'none');
    cell(to)?.focus({ preventScroll: true });
  };

  const cellKey = (index: number, event: ReactKeyboardEvent<HTMLElement>) => {
    const rtl = event.currentTarget.matches(':dir(rtl)');
    const own = panel(index);
    switch (event.key) {
      case rtl ? 'ArrowLeft' : 'ArrowRight':
        move(wrap(index, 1, count));
        break;
      case rtl ? 'ArrowRight' : 'ArrowLeft':
        move(wrap(index, -1, count));
        break;
      case 'Home':
        move(0);
        break;
      case 'End':
        move(count - 1);
        break;
      // Enter and Space would toggle through popovertarget and close an open menu
      case 'ArrowDown':
      case 'Enter':
      case ' ':
        if (own) showMenu(own, 'first');
        break;
      case 'ArrowUp':
        if (own) showMenu(own, 'last');
        break;
      default:
        return;
    }
    event.preventDefault();
  };

  const hover = (index: number, event: ReactPointerEvent) => {
    if (event.pointerType === 'touch') return;
    const open = openPanel();
    if (open && open !== panel(index)) move(index);
  };

  const edge = (index: number, step: 1 | -1) => {
    const to = wrap(index, step, count);
    const next = panel(to);
    if (next) showMenu(next, 'none');
    cell(to)?.focus({ preventScroll: true });
  };

  return (
    <div
      className={cx('canon-menu-bar', className)}
      role="menubar"
      ref={useRefs(root, closeOnLeave, ref)}
      {...rest}
    >
      <CanonGrid className="canon-menu-bar-cells">
        {menus.map((menu, index) => (
          <CanonButton
            key={index}
            className={cx(
              'canon-menu-bar-cell',
              index === opened && 'canon-menu-bar-cell--open',
            )}
            role="menuitem"
            tabIndex={index === current ? 0 : -1}
            data-menu-cell={index}
            kind="cell"
            text={menu.title}
            onKeyDown={(event) => cellKey(index, event)}
            onPointerEnter={(event) => hover(index, event)}
            onFocus={() => setCurrent(index)}
          />
        ))}
      </CanonGrid>
      {menus.map((menu, index) => (
        <CanonMenuList
          key={index}
          id={`${id}-${index}`}
          items={menu.items}
          onSelect={(item) => onSelect?.(item, index)}
          onEdge={(step) => edge(index, step)}
          ref={anchors[index]}
        />
      ))}
    </div>
  );
}
