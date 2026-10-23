import {
	useCallback,
	useRef,
	type HTMLAttributes,
	type ReactNode,
	type Ref,
} from 'react';
import { afterPress, attach, isOpen } from '@canon/lib/popover.ts';
import {
	CanonMenuList,
	showMenu,
	type CanonMenuEntry,
	type CanonMenuItem,
} from './canon-menu.tsx';
import { cx } from '../lib/class-names.ts';
import { useLatest, useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-context-menu.css';

export interface CanonContextMenuProps extends Omit<
	HTMLAttributes<HTMLDivElement>,
	'onSelect'
> {
	items: CanonMenuEntry[];
	onSelect?: (item: CanonMenuItem) => void;
	/** The area the menu belongs to. */
	children?: ReactNode;
	ref?: Ref<HTMLDivElement>;
}

/**
 * A menu opened at the pointer by a secondary click in the area, or below
 * the focused element by Shift+F10 or the context menu key. Focus goes
 * back to where it was when the menu closes.
 */
export default function CanonContextMenu({
	items,
	onSelect,
	children,
	className,
	ref,
	...rest
}: CanonContextMenuProps) {
	const returnTo = useRef<Element | null>(null);
	const latest = useLatest(onSelect);

	const setup = useCallback((root: HTMLDivElement) => {
		// the last two children, after the consumer's block
		const panel = root.lastElementChild as HTMLElement;
		const point = panel.previousElementSibling as HTMLElement;
		const detach = attach(panel, point, {
			placement: 'bottom-start',
			gap: '0px',
			returnFocus: () => returnTo.current,
		});

		// client coordinates are physical, so left and top
		const openAt = (x: number, y: number) => {
			returnTo.current = document.activeElement;
			point.style.left = `${x}px`;
			point.style.top = `${y}px`;
			showMenu(panel, 'first');
		};
		const below = (element: Element) => {
			const box = element.getBoundingClientRect();
			openAt(
				element.matches(':dir(rtl)')
					? box.right
					: box.left,
				box.bottom,
			);
		};
		const contextmenu = (event: MouseEvent) => {
			event.preventDefault();
			// the key already opened it, or the click is on the menu itself
			if (isOpen(panel)) return;
			// a context menu key the keydown did not see reports no position
			if (event.clientX === 0 && event.clientY === 0)
				below(event.target as Element);
			else {
				const { clientX, clientY } = event;
				afterPress(event.buttons !== 0, () =>
					openAt(clientX, clientY),
				);
			}
		};
		const keydown = (event: KeyboardEvent) => {
			const key =
				event.key === 'ContextMenu' ||
				(event.shiftKey && event.key === 'F10');
			if (!key || panel.contains(event.target as Node))
				return;
			event.preventDefault();
			below(event.target as Element);
		};
		root.addEventListener('contextmenu', contextmenu);
		root.addEventListener('keydown', keydown);
		return () => {
			root.removeEventListener('contextmenu', contextmenu);
			root.removeEventListener('keydown', keydown);
			detach();
		};
	}, []);

	const select = useCallback(
		(item: CanonMenuItem) => latest.current?.(item),
		[latest],
	);

	return (
		<div
			className={cx('canon-context-menu', className)}
			ref={useRefs(setup, ref)}
			{...rest}
		>
			{children}
			<span
				className="canon-context-menu-point"
				aria-hidden="true"
			></span>
			<CanonMenuList items={items} onSelect={select} />
		</div>
	);
}
