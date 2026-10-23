import {
	Fragment,
	useCallback,
	useId,
	useRef,
	type HTMLAttributes,
	type MouseEvent as ReactMouseEvent,
	type PointerEvent as ReactPointerEvent,
	type ReactNode,
	type Ref,
	type RefCallback,
} from 'react';
import {
	isSeparator,
	menuRole,
	typeAhead,
	typeAheadMs,
	wrap,
	type CanonMenuEntry as Entry,
	type CanonMenuItem as Item,
	type CanonMenuRole,
} from '@canon/lib/menu.ts';
import {
	attach,
	focusLeaves,
	hide,
	isOpen,
	panelFor,
	type CanonPlacement,
} from '@canon/lib/popover.ts';
import CanonRule from './canon-rule.tsx';
import { cx } from '../lib/class-names.ts';
import { Check, ChevronRight } from '../lib/control-icons.tsx';
import { useLatest, useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-popover.css';
import '@canon/components/canon-menu.css';

export type CanonMenuEntry = Entry<ReactNode>;
export type CanonMenuItem = Item<ReactNode>;

// opened by our own code, which places focus itself
const claimed = new WeakSet<HTMLElement>();

function ownItems(panel: HTMLElement): HTMLElement[] {
	return [...panel.children].filter(
		(child): child is HTMLElement =>
			child instanceof HTMLElement &&
			child.classList.contains('canon-menu-item'),
	);
}

/** Opens a CanonMenuList panel if it is closed and focuses its first or last item, or leaves focus where it is. */
export function showMenu(panel: HTMLElement, focus: 'first' | 'last' | 'none') {
	if (!isOpen(panel)) {
		claimed.add(panel);
		panel.showPopover();
	}
	if (focus === 'none') return;
	const items = ownItems(panel);
	(focus === 'first' ? items[0] : items.at(-1))?.focus({
		preventScroll: true,
	});
}

interface Row {
	index: number;
	item?: CanonMenuItem;
	role?: CanonMenuRole;
	checked?: 'true' | 'false';
	sub?: CanonMenuEntry[];
	subId?: string;
}

function rowsOf(items: CanonMenuEntry[], sub: boolean, id: string): Row[] {
	return items.map((entry, index) => {
		if (isSeparator(entry)) return { index };
		const subItems =
			!sub && entry.items?.length ? entry.items : undefined;
		const checkable =
			entry.kind === 'checkbox' || entry.kind === 'radio';
		return {
			index,
			item: entry,
			role: menuRole(entry),
			checked: checkable
				? entry.checked === true
					? 'true'
					: 'false'
				: undefined,
			sub: subItems,
			subId: subItems ? `${id}-${index}` : undefined,
		};
	});
}

function subPanelOf(panel: HTMLElement | null, row: Row | undefined) {
	if (!panel || !row?.subId) return undefined;
	return (
		panel.querySelector<HTMLElement>(`#${CSS.escape(row.subId)}`) ??
		undefined
	);
}

// the item before a submenu panel is the item that opens it
function anchorSubmenu(sub: HTMLDivElement | null) {
	const item = sub?.previousElementSibling;
	if (!sub || !(item instanceof HTMLElement)) return;
	return attach(sub, item, {
		placement: 'right-start',
		invokes: true,
		gap: '0px',
	});
}

export interface CanonMenuListProps extends Omit<
	HTMLAttributes<HTMLDivElement>,
	'onSelect' | 'children'
> {
	items: CanonMenuEntry[];
	onSelect: (item: CanonMenuItem) => void;
	/** Arrow keys past the inline edge: 1 towards the end, -1 towards the start. A menu bar moves to its neighbour. */
	onEdge?: (step: 1 | -1) => void;
	/** A submenu: the inline start arrow closes it, and its items open no further menus. */
	sub?: boolean;
	ref?: Ref<HTMLDivElement>;
}

/**
 * The popover panel of a menu (role menu) that CanonMenu, CanonContextMenu
 * and CanonMenuBar open. The owner anchors it with `attach` and opens it
 * with its trigger or `showMenu`.
 */
export function CanonMenuList({
	items,
	onSelect,
	onEdge,
	sub = false,
	id: givenId,
	className,
	ref,
	...rest
}: CanonMenuListProps) {
	const ownId = `${useId()}-list`;
	const panelRef = useRef<HTMLDivElement>(null);
	const typed = useRef({ text: '', at: -Infinity });
	const rows = rowsOf(items, sub, ownId);
	const latest = useLatest({ rows, sub, onSelect, onEdge });

	const select = useCallback(
		(item: CanonMenuItem) => {
			if (!latest.current.sub && panelRef.current)
				hide(panelRef.current);
			latest.current.onSelect(item);
		},
		[latest],
	);

	const setup = useCallback(
		(panel: HTMLDivElement) => {
			const toggle = (event: ToggleEvent) => {
				if (
					event.newState !== 'open' ||
					claimed.delete(panel)
				)
					return;
				if (!panel.contains(document.activeElement))
					ownItems(panel)[0]?.focus({
						preventScroll: true,
					});
			};

			const find = (
				event: KeyboardEvent,
				list: HTMLElement[],
				at: number,
			) => {
				const { key } = event;
				if (key.length !== 1 || key === ' ')
					return false;
				if (
					event.ctrlKey ||
					event.metaKey ||
					event.altKey
				)
					return false;
				const state = typed.current;
				state.text =
					event.timeStamp - state.at < typeAheadMs
						? state.text + key
						: key;
				state.at = event.timeStamp;
				const titles = list.map(
					(element) =>
						latest.current.rows[
							Number(
								element.dataset[
									'index'
								],
							)
						]?.item?.title ?? '',
				);
				const found = typeAhead(titles, state.text, at);
				if (found >= 0)
					list[found]!.focus({
						preventScroll: true,
					});
				return true;
			};

			const keydown = (event: KeyboardEvent) => {
				const target = event.target as HTMLElement;
				if (target.parentElement !== panel) return;
				const { rows, sub, onEdge } = latest.current;
				const list = ownItems(panel);
				const at = list.indexOf(target);
				const row =
					rows[Number(target.dataset['index'])];
				const go = (index: number) =>
					list[index]?.focus({
						preventScroll: true,
					});
				const rtl = panel.matches(':dir(rtl)');
				const toEnd = rtl ? 'ArrowLeft' : 'ArrowRight';
				const toStart = rtl
					? 'ArrowRight'
					: 'ArrowLeft';
				switch (event.key) {
					case 'ArrowDown':
						go(wrap(at, 1, list.length));
						break;
					case 'ArrowUp':
						go(wrap(at, -1, list.length));
						break;
					case 'Home':
						go(0);
						break;
					case 'End':
						go(list.length - 1);
						break;
					case toEnd: {
						const opens = subPanelOf(
							panel,
							row,
						);
						if (
							opens &&
							!row?.item?.disabled
						)
							showMenu(
								opens,
								'first',
							);
						else onEdge?.(1);
						break;
					}
					case toStart:
						if (sub) hide(panel);
						else onEdge?.(-1);
						break;
					default:
						if (!find(event, list, at))
							return;
				}
				event.preventDefault();
			};

			const focusout = (event: FocusEvent) => {
				if (
					!latest.current.sub &&
					focusLeaves(panel, event)
				)
					hide(panel);
			};

			panel.addEventListener('toggle', toggle);
			panel.addEventListener('keydown', keydown);
			panel.addEventListener('focusout', focusout);
			return () => {
				panel.removeEventListener('toggle', toggle);
				panel.removeEventListener('keydown', keydown);
				panel.removeEventListener('focusout', focusout);
			};
		},
		[latest],
	);

	const activate = (row: Row, event: ReactMouseEvent) => {
		if (row.sub) {
			// the item is the submenu's popovertarget; a second click must not close it
			event.preventDefault();
			const opens = subPanelOf(panelRef.current, row);
			if (opens && !row.item?.disabled)
				showMenu(opens, 'first');
			return;
		}
		if (row.item && !row.item.disabled) select(row.item);
	};

	const hover = (row: Row, event: ReactPointerEvent<HTMLElement>) => {
		const panel = panelRef.current;
		if (event.pointerType === 'touch' || !panel) return;
		event.currentTarget.focus({ preventScroll: true });
		for (const open of panel.querySelectorAll<HTMLElement>(
			':scope > .canon-menu:popover-open',
		))
			if (open.id !== row.subId) open.hidePopover();
		const opens = subPanelOf(panelRef.current, row);
		if (opens && !row.item?.disabled) showMenu(opens, 'none');
	};

	const checks = items.some(
		(entry) => entry.kind === 'checkbox' || entry.kind === 'radio',
	);
	const icons = items.some(
		(entry) => !isSeparator(entry) && entry.icon !== undefined,
	);

	return (
		<div
			id={givenId ?? ownId}
			className={cx(
				'canon-popover canon-menu',
				checks && 'canon-menu--checks',
				icons && 'canon-menu--icons',
				className,
			)}
			popover="auto"
			role="menu"
			ref={useRefs(panelRef, setup, ref)}
			{...rest}
		>
			{rows.map((row) =>
				row.item ? (
					<Fragment key={row.index}>
						<button
							type="button"
							className={cx(
								'canon-menu-item',
								row.item
									.destructive &&
									'canon-menu-item--destructive',
							)}
							role={row.role}
							tabIndex={-1}
							data-index={row.index}
							aria-checked={
								row.checked
							}
							aria-disabled={
								row.item
									.disabled
									? 'true'
									: undefined
							}
							aria-haspopup={
								row.sub
									? 'menu'
									: undefined
							}
							onClick={(event) =>
								activate(
									row,
									event,
								)
							}
							onPointerEnter={(
								event,
							) => hover(row, event)}
						>
							<span
								className="canon-menu-item-check"
								aria-hidden="true"
							>
								{row.item
									.checked && (
									<Check />
								)}
							</span>
							<span
								className="canon-menu-item-icon"
								aria-hidden="true"
							>
								{row.item.icon}
							</span>
							<span className="canon-menu-item-title">
								{row.item.title}
							</span>
							{row.item.shortcut && (
								<kbd className="canon-menu-item-shortcut">
									{
										row
											.item
											.shortcut
									}
								</kbd>
							)}
							{row.sub && (
								<span
									className="canon-menu-item-more"
									aria-hidden="true"
								>
									<ChevronRight />
								</span>
							)}
						</button>
						{row.sub && (
							<CanonMenuList
								id={row.subId}
								items={row.sub}
								sub
								onSelect={
									select
								}
								onEdge={onEdge}
								ref={
									anchorSubmenu
								}
							/>
						)}
					</Fragment>
				) : (
					<CanonRule key={row.index} />
				),
			)}
		</div>
	);
}

export interface CanonMenuProps extends Omit<
	HTMLAttributes<HTMLDivElement>,
	'onSelect' | 'children'
> {
	items: CanonMenuEntry[];
	/** Default bottom-start. */
	placement?: CanonPlacement;
	onSelect?: (item: CanonMenuItem) => void;
	/** Put `trigger` as the ref of the button that opens the menu. */
	children: (menu: {
		trigger: RefCallback<HTMLButtonElement>;
	}) => ReactNode;
	ref?: Ref<HTMLDivElement>;
}

/**
 * A dropdown menu opened by the consumer's button: a click, Enter or Space
 * opens it at the first item, the down and up arrows at the first and last.
 * Choosing an item closes it and reports the item.
 */
export default function CanonMenu({
	items,
	placement = 'bottom-start',
	onSelect,
	children,
	...rest
}: CanonMenuProps) {
	const id = `${useId()}-menu`;
	const latest = useLatest(onSelect);

	const trigger = useCallback(
		(button: HTMLButtonElement) => {
			const panel = panelFor(button, id);
			const detach = attach(panel, button, {
				placement,
				invokes: true,
				haspopup: 'menu',
			});
			const keydown = (event: KeyboardEvent) => {
				if (
					event.key !== 'ArrowDown' &&
					event.key !== 'ArrowUp'
				)
					return;
				event.preventDefault();
				showMenu(
					panel,
					event.key === 'ArrowDown'
						? 'first'
						: 'last',
				);
			};
			button.addEventListener('keydown', keydown);
			return () => {
				button.removeEventListener('keydown', keydown);
				detach();
			};
		},
		[id, placement],
	);
	const select = useCallback(
		(item: CanonMenuItem) => latest.current?.(item),
		[latest],
	);

	return (
		<>
			{children({ trigger })}
			<CanonMenuList
				id={id}
				items={items}
				onSelect={select}
				{...rest}
			/>
		</>
	);
}
