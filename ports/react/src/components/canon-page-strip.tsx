import {
	useEffect,
	useRef,
	useState,
	type CSSProperties,
	type DragEvent,
	type HTMLAttributes,
	type KeyboardEvent,
	type MouseEvent,
	type PointerEvent,
} from 'react';
import { afterPress, isOpen } from '@canon/lib/popover.ts';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-page-strip.css';

/** A rectangle in PDF points, origin at the bottom left. */
export interface PageRect {
	x: number;
	y: number;
	width: number;
	height: number;
}

export interface CanonPage {
	/** PDF points. */
	size: { width: number; height: number };
	/** The part of the page in use, dashed when it is not the whole page; default the whole page. */
	area?: PageRect;
	/** Where the picture is drawn, clipped to `area`; default the whole page. */
	placement?: PageRect;
	/** URL of the picture. */
	picture?: string;
	name?: string;
	/** Sheets stacked behind, up to three, for a page that stands for several. */
	depth?: number;
	/** Clockwise degrees in quarter turns, the picture only. */
	turn?: number;
}

export interface CanonPageMenuItem {
	title: string;
	action: () => void;
	destructive?: boolean;
}

export interface CanonPageStripProps extends Omit<
	HTMLAttributes<HTMLDivElement>,
	'onSelect' | 'onDrop'
> {
	pages: CanonPage[];
	/** Pages drag to new places, by pointer or Alt and the arrow keys; files drop in. */
	reorders?: boolean;
	/** A page moved; the consumer moves it in `pages`. */
	onMove?: (from: number, to: number) => void;
	/** Files dropped in before `index`, already filtered by `dropTypes`. */
	onDrop?: (index: number, files: File[]) => void;
	/** MIME types taken from outside, `image/*` style; default images. */
	dropTypes?: string[];
	/** Items of the menu a long press or a secondary click opens on a page. */
	menu?: (index: number) => CanonPageMenuItem[] | undefined;
	onSelect?: (index: number) => void;
	/** The lit page. */
	selected?: number;
	/** Shown when there are no pages; default Pages. */
	empty?: string;
}

/** Height of a canvas holding the strip. */
export const pageStripHeight = 196;
const sheetOffset = 4;
const longPressMs = 500;
const dragType = 'application/x-canon-page';

// farthest sheet first, so the nearer ones paint over it
function sheets(depth: number): CSSProperties[] {
	return Array.from({ length: depth }, (_, k) => {
		const step = (depth - k) * sheetOffset;
		return { translate: `${step}px ${-step}px` };
	});
}

function pct(value: number) {
	return `${Math.round(value * 10000) / 100}%`;
}

function paperStyle(page: CanonPage) {
	const { width, height } = page.size;
	const ratio = Math.max(width, 1) / Math.max(height, 1);
	const room = Math.min(page.depth ?? 0, 3) * sheetOffset;
	return {
		'--canon-page-ratio': ratio,
		'--canon-page-room': `${room}px`,
	} as CSSProperties;
}

/** Top, right, bottom, left of a PDF rect as shares of the page, top-left origin. */
function inset(rect: PageRect, page: CanonPage) {
	const { width, height } = page.size;
	return {
		top: (height - rect.y - rect.height) / height,
		left: rect.x / width,
		right: (width - rect.x - rect.width) / width,
		bottom: rect.y / height,
	};
}

function insetText(box: ReturnType<typeof inset>) {
	return `${pct(box.top)} ${pct(box.right)} ${pct(box.bottom)} ${pct(box.left)}`;
}

function isWhole(rect: PageRect | undefined, page: CanonPage) {
	return (
		!rect ||
		(rect.x === 0 &&
			rect.y === 0 &&
			rect.width === page.size.width &&
			rect.height === page.size.height)
	);
}

function matches(type: string, patterns: string[]) {
	return patterns.some((pattern) =>
		pattern.endsWith('/*')
			? type.startsWith(pattern.slice(0, -1))
			: type === pattern,
	);
}

function wholeRect(page: CanonPage): PageRect {
	return { x: 0, y: 0, width: page.size.width, height: page.size.height };
}

function cell(page: CanonPage, index: number) {
	const area = inset(page.area ?? wholeRect(page), page);
	const placement = inset(page.placement ?? wholeRect(page), page);
	const quarter = ((((page.turn ?? 0) / 90) % 4) + 4) % 4;
	const w = page.size.width;
	const h = page.size.height;
	const placed = page.placement ?? wholeRect(page);
	const sideways = quarter % 2 === 1;
	return {
		paperStyle: paperStyle(page),
		sheets: sheets(Math.min(page.depth ?? 0, 3)),
		clip: { clipPath: `inset(${insetText(area)})` },
		pictureStyle: {
			left: pct(placement.left + placed.width / w / 2),
			top: pct(placement.top + placed.height / h / 2),
			width: pct(
				(sideways ? placed.height : placed.width) / w,
			),
			height: pct(
				(sideways ? placed.width : placed.height) / h,
			),
			transform: `translate(-50%, -50%) rotate(${quarter * 90}deg)`,
		},
		dashed: isWhole(page.area, page)
			? undefined
			: { inset: insetText(area) },
		label: page.name
			? `Page ${index + 1}, ${page.name}`
			: `Page ${index + 1}`,
	};
}

/**
 * Pages to scale in a sideways row, numbered, with an optional name under
 * each: drag to reorder, drop files in, a long-press menu, a tap that lights
 * a page, and sheets stacked behind a page that stands for several.
 */
export default function CanonPageStrip({
	pages,
	reorders,
	onMove,
	onDrop,
	dropTypes = ['image/*'],
	menu,
	onSelect,
	selected,
	empty,
	className,
	...rest
}: CanonPageStripProps) {
	const [dropAt, setDropAt] = useState<number>();
	const [menuItems, setMenuItems] = useState<CanonPageMenuItem[]>([]);
	const dragFrom = useRef<number>(undefined);
	const pressTimer = useRef<number>(undefined);
	const menuElement = useRef<HTMLDivElement>(null);
	const count = pages.length;

	const cancelPress = () => window.clearTimeout(pressTimer.current);
	useEffect(() => () => window.clearTimeout(pressTimer.current), []);

	// keyboard reordering
	const onKey = (index: number, event: KeyboardEvent<HTMLElement>) => {
		if (!reorders || !event.altKey) return;
		const list = event.currentTarget.closest('ol');
		const rtl = list && getComputedStyle(list).direction === 'rtl';
		const forward = rtl ? 'ArrowLeft' : 'ArrowRight';
		const back = rtl ? 'ArrowRight' : 'ArrowLeft';
		const to =
			event.key === forward
				? index + 1
				: event.key === back
					? index - 1
					: NaN;
		if (Number.isNaN(to)) return;
		event.preventDefault();
		if (to < 0 || to >= count) return;
		onMove?.(index, to);
		requestAnimationFrame(() =>
			list
				?.querySelector<HTMLElement>(
					`[data-page-index="${to}"] .canon-page-strip-page`,
				)
				?.focus(),
		);
	};

	const onDragStart = (index: number, event: DragEvent<HTMLElement>) => {
		cancelPress();
		if (!reorders) {
			event.preventDefault();
			return;
		}
		dragFrom.current = index;
		event.dataTransfer.effectAllowed = 'move';
		event.dataTransfer.setData(dragType, String(index));
		const paper = event.currentTarget.querySelector(
			'.canon-page-strip-paper',
		);
		if (paper) event.dataTransfer.setDragImage(paper, 0, 0);
	};

	const onDragEnd = () => {
		dragFrom.current = undefined;
		setDropAt(undefined);
	};

	const accepts = (event: DragEvent) => {
		const transfer = event.dataTransfer;
		if (!reorders) return false;
		if (dragFrom.current !== undefined) return true;
		if (!transfer.types.includes('Files')) return false;
		const types = [...transfer.items]
			.filter((item) => item.kind === 'file')
			.map((item) => item.type);
		return (
			types.length === 0 ||
			types.some((t) => matches(t, dropTypes))
		);
	};

	const destination = (list: HTMLElement, x: number) => {
		const rtl = getComputedStyle(list).direction === 'rtl';
		const items = [
			...list.querySelectorAll<HTMLElement>(
				'[data-page-index]',
			),
		];
		const index = items.findIndex((item) => {
			const box = item.getBoundingClientRect();
			const middle = box.left + box.width / 2;
			return rtl ? x > middle : x < middle;
		});
		return index === -1 ? items.length : index;
	};

	const onDragOver = (event: DragEvent<HTMLOListElement>) => {
		if (!accepts(event)) return;
		event.preventDefault();
		event.dataTransfer.dropEffect =
			dragFrom.current !== undefined ? 'move' : 'copy';
		setDropAt(destination(event.currentTarget, event.clientX));
	};

	const onDragLeave = (event: DragEvent<HTMLOListElement>) => {
		if (
			!event.currentTarget.contains(
				event.relatedTarget as Node | null,
			)
		)
			setDropAt(undefined);
	};

	const onDropFiles = (event: DragEvent<HTMLOListElement>) => {
		if (!accepts(event)) return;
		event.preventDefault();
		const at = destination(event.currentTarget, event.clientX);
		const from = dragFrom.current;
		onDragEnd();
		if (from !== undefined) {
			const to = Math.min(at > from ? at - 1 : at, count - 1);
			if (to !== from) onMove?.(from, to);
			return;
		}
		const files = [...event.dataTransfer.files].filter((file) =>
			matches(file.type, dropTypes),
		);
		if (files.length > 0) onDrop?.(at, files);
	};

	const openMenu = (
		index: number,
		x: number,
		y: number,
		held: boolean,
	) => {
		const items = menu?.(index);
		const element = menuElement.current;
		if (!items?.length || !element) return false;
		afterPress(held, () => {
			// a touch long press can also fire contextmenu
			if (isOpen(element)) return;
			setMenuItems(items);
			element.style.left = `${x}px`;
			element.style.top = `${y}px`;
			element.showPopover();
			requestAnimationFrame(() =>
				element
					.querySelector<HTMLElement>(
						'[role=menuitem]',
					)
					?.focus(),
			);
		});
		return true;
	};

	const onContextMenu = (
		index: number,
		event: MouseEvent<HTMLElement>,
	) => {
		let { clientX: x, clientY: y } = event;
		// the context menu key reports no position
		if (x === 0 && y === 0) {
			const box = event.currentTarget.getBoundingClientRect();
			x = box.left;
			y = box.bottom;
		}
		if (openMenu(index, x, y, event.buttons !== 0))
			event.preventDefault();
	};

	const onPointerDown = (index: number, event: PointerEvent) => {
		if (event.pointerType !== 'touch' || !menu) return;
		const { clientX: x, clientY: y } = event;
		cancelPress();
		pressTimer.current = window.setTimeout(
			() => openMenu(index, x, y, true),
			longPressMs,
		);
	};

	const choose = (item: CanonPageMenuItem) => {
		menuElement.current?.hidePopover();
		item.action();
	};

	return (
		<div className={cx('canon-page-strip', className)} {...rest}>
			{count > 0 ? (
				<ol
					className="canon-page-strip-list"
					onDragOver={onDragOver}
					onDragLeave={onDragLeave}
					onDrop={onDropFiles}
				>
					{pages.map((page, index) => {
						const c = cell(page, index);
						const lit = index === selected;
						return (
							<li
								key={index}
								className={cx(
									'canon-page-strip-cell',
									lit &&
										'canon-page-strip-cell--lit',
									dropAt ===
										index &&
										'canon-page-strip-cell--drop-before',
									dropAt ===
										count &&
										index ===
											count -
												1 &&
										'canon-page-strip-cell--drop-after',
								)}
								style={
									c.paperStyle
								}
								data-page-index={
									index
								}
								draggable={
									reorders
										? true
										: undefined
								}
								onDragStart={(
									event,
								) =>
									onDragStart(
										index,
										event,
									)
								}
								onDragEnd={
									onDragEnd
								}
							>
								<button
									type="button"
									className="canon-page-strip-page"
									aria-label={
										c.label
									}
									aria-current={
										lit
											? 'true'
											: undefined
									}
									aria-haspopup={
										menu
											? 'menu'
											: undefined
									}
									aria-keyshortcuts={
										reorders
											? 'Alt+ArrowLeft Alt+ArrowRight'
											: undefined
									}
									onClick={() =>
										onSelect?.(
											index,
										)
									}
									onKeyDown={(
										event,
									) =>
										onKey(
											index,
											event,
										)
									}
									onContextMenu={(
										event,
									) =>
										onContextMenu(
											index,
											event,
										)
									}
									onPointerDown={(
										event,
									) =>
										onPointerDown(
											index,
											event,
										)
									}
									onPointerUp={
										cancelPress
									}
									onPointerCancel={
										cancelPress
									}
									onPointerLeave={
										cancelPress
									}
								>
									<span className="canon-page-strip-art">
										<span className="canon-page-strip-stack">
											{c.sheets.map(
												(
													sheet,
													k,
												) => (
													<span
														key={
															k
														}
														className="canon-page-strip-sheet"
														style={
															sheet
														}
													/>
												),
											)}
											<span className="canon-page-strip-paper">
												{page.picture && (
													<span
														className="canon-page-strip-clip"
														style={
															c.clip
														}
													>
														<img
															className="canon-page-strip-picture"
															src={
																page.picture
															}
															alt=""
															draggable="false"
															style={
																c.pictureStyle
															}
														/>
													</span>
												)}
												{c.dashed && (
													<span
														className="canon-page-strip-area"
														style={
															c.dashed
														}
													/>
												)}
											</span>
										</span>
									</span>
									<span
										className={cx(
											'canon-page-strip-number',
											page.name &&
												'canon-page-strip-number--named',
										)}
									>
										{index +
											1}
									</span>
									{page.name && (
										<span className="canon-page-strip-name">
											{
												page.name
											}
										</span>
									)}
								</button>
							</li>
						);
					})}
				</ol>
			) : (
				<p className="canon-page-strip-empty">
					{empty || 'Pages'}
				</p>
			)}
			<div
				className="canon-page-strip-menu"
				popover="auto"
				role="menu"
				ref={menuElement}
			>
				{menuItems.map((item, i) => (
					<button
						key={i}
						type="button"
						role="menuitem"
						className={cx(
							'canon-page-strip-menu-item',
							item.destructive &&
								'canon-page-strip-menu-item--destructive',
						)}
						onClick={() => choose(item)}
					>
						{item.title}
					</button>
				))}
			</div>
		</div>
	);
}
