import {
	useCallback,
	useEffect,
	useMemo,
	useRef,
	useState,
	type CSSProperties,
	type HTMLAttributes,
	type Ref,
} from 'react';
import { opensSlot, type Key } from '@canon/lib/math/expression.ts';
import {
	glideSpring,
	keyHeights,
	label,
	labelShare,
	menuScale,
	nameScale,
	pages,
	returnDelay,
	spoken,
	tabHeights,
	type Family,
	type Spec,
} from '@canon/lib/math/keypad.ts';
import { canvasMetrics } from '@canon/lib/math/measure.ts';
import { Typesetter, type Box } from '@canon/lib/math/typeset.ts';
import { springEasing } from '@canon/lib/motion.ts';
import CanonMathKey from './canon-math-key.tsx';
import CanonMathTabs from './canon-math-tabs.tsx';
import { cx } from '../lib/class-names.ts';
import { Delete } from '../lib/control-icons.tsx';
import { useLatest } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-keypad.css';

export interface CanonMathKeypadProps extends HTMLAttributes<HTMLDivElement> {
	/** The first letter key, and the variable of d/dx, ∫ and lim; default x. */
	variable?: string;
	/** The short keys, for a short window. */
	short?: boolean;
	onKey?: (key: Key) => void;
	onDone?: () => void;
	ref?: Ref<HTMLDivElement>;
}

interface PlacedKey {
	spec: Spec;
	face: Box;
	label: string;
	id: string;
	style: CSSProperties;
}

interface Menu {
	keys: { key: Key; face: Box; label: string }[];
	family: Family;
	page: number;
	anchor: HTMLElement;
	cell: { width: number; height: number };
}

function still(): boolean {
	return matchMedia('(prefers-reduced-motion: reduce)').matches;
}

/** Opens over its key, growing out of the key's top edge; a touch elsewhere or Escape closes it. */
function placeMenu(panel: HTMLElement, menu: Menu, close: () => void) {
	const root = panel.parentElement!;
	const box = root.getBoundingClientRect();
	const anchor = menu.anchor.getBoundingClientRect();
	const width = panel.offsetWidth;
	const height = panel.offsetHeight;
	const midX = anchor.left + anchor.width / 2 - box.left;
	const left = Math.min(
		Math.max(midX - width / 2, 6),
		box.width - 6 - width,
	);
	const top = anchor.top - box.top - height - 6;
	panel.style.insetInlineStart = `${left}px`;
	panel.style.insetBlockStart = `${top}px`;
	if (!still()) {
		const dx = (midX - (left + width / 2)) * 0.6;
		const dy = (anchor.top - box.top - (top + height / 2)) * 0.6;
		panel.animate(
			[
				{
					transform: `translate(${dx}px, ${dy}px) scale(0.4)`,
					opacity: 0,
				},
				{ transform: 'none', opacity: 1 },
			],
			{ duration: 340, easing: springEasing(0.74) },
		);
	}
	panel.querySelector<HTMLElement>('button')?.focus({
		preventScroll: true,
	});
	const outside = (event: PointerEvent) => {
		if (!panel.contains(event.target as Node)) close();
	};
	const escape = (event: KeyboardEvent) => {
		if (event.key !== 'Escape') return;
		event.preventDefault();
		event.stopPropagation();
		close();
		menu.anchor.focus({ preventScroll: true });
	};
	document.addEventListener('pointerdown', outside, true);
	document.addEventListener('keydown', escape, true);
	return () => {
		document.removeEventListener('pointerdown', outside, true);
		document.removeEventListener('keydown', escape, true);
	};
}

/**
 * Maths keys on four swipeable pages (numbers and operators, functions,
 * calculus, letters and constants), with delete, clear and Done beside every
 * page. Hyperbolic and reciprocal trig sit in submenus. A slot key typed on a
 * later page returns to the numbers, since the slot usually takes a number
 * next.
 */
export default function CanonMathKeypad({
	variable = 'x',
	short,
	onKey,
	onDone,
	className,
	style,
	...rest
}: CanonMathKeypadProps) {
	const [progress, setProgress] = useState(0);
	const [pageWidth, setPageWidth] = useState(0);
	const [menu, setMenu] = useState<Menu>();
	const pagerRef = useRef<HTMLDivElement>(null);
	const glide = useRef<number>(undefined);
	const tracking = useRef(false);

	const keyHeight = short ? keyHeights.short : keyHeights.regular;
	const labelSize = Math.round(keyHeight * labelShare);
	const page = Math.min(Math.max(Math.round(progress), 0), 3);
	const latest = useLatest({ page });

	/** Faces are set once per variable and key size. */
	const built = useMemo<PlacedKey[][]>(
		() =>
			pages(variable).map((specs, page) =>
				specs.map((spec) => ({
					spec,
					face: spec.menu
						? new Typesetter(
								canvasMetrics,
								labelSize *
									menuScale,
							).text(spec.menu.title)
						: label(
								spec.key,
								variable,
								labelSize *
									spec.scale,
								canvasMetrics,
							),
					label:
						spec.menu?.title ??
						spoken(spec.key, variable),
					id: `${page}-${spec.x}-${spec.y}`,
					style: {
						gridColumn: `${spec.x + 1} / span ${spec.w}`,
						gridRow: `${spec.y + 1} / span ${spec.h}`,
						'--canon-math-x': spec.x,
						'--canon-math-w': spec.w,
					} as CSSProperties,
				})),
			),
		[variable, labelSize],
	);

	const clearFace = useMemo(
		() =>
			label(
				{ kind: 'clear' },
				variable,
				labelSize * 0.9,
				canvasMetrics,
			),
		[variable, labelSize],
	);

	const stopGlide = useCallback(() => {
		if (glide.current !== undefined)
			cancelAnimationFrame(glide.current);
		glide.current = undefined;
		pagerRef.current?.classList.remove(
			'canon-math-keypad-pager--gliding',
		);
	}, []);

	const closeMenu = () => setMenu(undefined);

	const show = useCallback(
		(index: number) => {
			setMenu(undefined);
			const pager = pagerRef.current;
			if (!pager) return;
			const width = pager.clientWidth;
			const target = Math.min(Math.max(index, 0), 3) * width;
			stopGlide();
			if (width === 0 || still()) {
				pager.scrollLeft = target;
				return;
			}
			const from = pager.scrollLeft;
			const start = performance.now();
			const omega = (2 * Math.PI) / glideSpring.response;
			const zeta = glideSpring.damping;
			const damped = omega * Math.sqrt(1 - zeta * zeta);
			pager.classList.add('canon-math-keypad-pager--gliding');
			const frame = (now: number) => {
				const t = (now - start) / 1000;
				const envelope = Math.exp(-zeta * omega * t);
				const x =
					target +
					(from - target) *
						envelope *
						(Math.cos(damped * t) +
							((zeta * omega) /
								damped) *
								Math.sin(
									damped *
										t,
								));
				if (
					t > 1.2 ||
					(t > 0.2 && Math.abs(x - target) < 0.3)
				) {
					pager.scrollLeft = target;
					stopGlide();
					return;
				}
				pager.scrollLeft = x;
				glide.current = requestAnimationFrame(frame);
			};
			glide.current = requestAnimationFrame(frame);
		},
		[stopGlide],
	);

	const type = (key: Key, from: number) => {
		closeMenu();
		onKey?.(key);
		if (from === 0 || !opensSlot(key)) return;
		window.setTimeout(() => {
			if (
				latest.current.page !== from ||
				glide.current !== undefined ||
				tracking.current
			)
				return;
			show(0);
		}, returnDelay * 1000);
	};

	const pager = useCallback(
		(pager: HTMLDivElement | null) => {
			pagerRef.current = pager;
			if (!pager) return;
			const scrolled = () => {
				const width = pager.clientWidth;
				if (width === 0) return;
				setPageWidth(width);
				setProgress(pager.scrollLeft / width);
			};
			const down = () => {
				tracking.current = true;
				stopGlide();
			};
			const up = () => (tracking.current = false);
			const resize = new ResizeObserver(() => {
				if (glide.current === undefined)
					pager.scrollLeft =
						latest.current.page *
						pager.clientWidth;
				scrolled();
			});
			resize.observe(pager);
			pager.addEventListener('scroll', scrolled, {
				passive: true,
			});
			pager.addEventListener('pointerdown', down);
			pager.addEventListener('wheel', down, {
				passive: true,
			});
			pager.addEventListener('pointerup', up);
			pager.addEventListener('pointercancel', up);
			pager.addEventListener('scrollend', up);
			return () => {
				stopGlide();
				pagerRef.current = null;
				resize.disconnect();
				pager.removeEventListener('scroll', scrolled);
				pager.removeEventListener('pointerdown', down);
				pager.removeEventListener('wheel', down);
				pager.removeEventListener('pointerup', up);
				pager.removeEventListener('pointercancel', up);
				pager.removeEventListener('scrollend', up);
			};
		},
		[latest, stopGlide],
	);

	const openMenu = (placed: PlacedKey, from: number) => {
		const items = placed.spec.menu;
		const anchor = pagerRef.current?.querySelector<HTMLElement>(
			`[data-canon-math-key="${placed.id}"]`,
		);
		if (!items || !anchor) return;
		setMenu({
			keys: items.keys.map((key) => ({
				key,
				face: label(
					key,
					variable,
					labelSize * nameScale,
					canvasMetrics,
				),
				label: spoken(key, variable),
			})),
			family: placed.spec.family,
			page: from,
			anchor,
			cell: {
				width: Math.max(
					64,
					anchor.offsetWidth / 3 + 12,
				),
				height: keyHeight,
			},
		});
	};

	const placing = useCallback(
		(panel: HTMLDivElement | null) =>
			panel && menu
				? placeMenu(panel, menu, () =>
						setMenu(undefined),
					)
				: undefined,
		[menu],
	);

	useEffect(() => stopGlide, [stopGlide]);

	return (
		<div
			className={cx('canon-math-keypad', className)}
			style={
				{
					'--canon-math-key-height': `${keyHeight}px`,
					'--canon-math-tab-height': `${short ? tabHeights.short : tabHeights.regular}px`,
					...style,
				} as CSSProperties
			}
			{...rest}
		>
			<CanonMathTabs progress={progress} onSelect={show} />
			<div className="canon-math-keypad-pager" ref={pager}>
				{built.map((keys, index) => {
					const offset = index - progress;
					return (
						<div
							key={index}
							className="canon-math-keypad-page"
							style={
								{
									'--canon-math-offset-px': `${offset * pageWidth}px`,
									'--canon-math-lead':
										offset >
										0
											? 1
											: 0,
									'--canon-math-fade':
										1 -
										0.7 *
											Math.min(
												1,
												Math.abs(
													offset,
												),
											),
								} as CSSProperties
							}
							inert={index !== page}
						>
							{keys.map((placed) =>
								placed.spec
									.menu ? (
									<CanonMathKey
										key={
											placed.id
										}
										face={
											placed.face
										}
										family={
											placed
												.spec
												.family
										}
										label={
											placed.label
										}
										menu
										onClick={() =>
											openMenu(
												placed,
												index,
											)
										}
										style={
											placed.style
										}
										data-canon-math-key={
											placed.id
										}
									/>
								) : (
									<CanonMathKey
										key={
											placed.id
										}
										face={
											placed.face
										}
										family={
											placed
												.spec
												.family
										}
										label={
											placed.label
										}
										onClick={() =>
											type(
												placed
													.spec
													.key,
												index,
											)
										}
										style={
											placed.style
										}
										data-canon-math-key={
											placed.id
										}
									/>
								),
							)}
						</div>
					);
				})}
			</div>
			<div className="canon-math-keypad-spine">
				<CanonMathKey
					family="operation"
					label="Delete"
					repeats
					onClick={() =>
						onKey?.({ kind: 'delete' })
					}
				>
					<Delete />
				</CanonMathKey>
				<CanonMathKey
					face={clearFace}
					family="clear"
					label="Clear"
					onClick={() =>
						onKey?.({ kind: 'clear' })
					}
				/>
				<CanonMathKey
					className="canon-math-keypad-done"
					family="done"
					label="Done"
					onClick={() => onDone?.()}
				>
					Done
				</CanonMathKey>
			</div>
			{menu && (
				<div
					className={`canon-math-submenu canon-math-key--${menu.family}`}
					role="menu"
					style={{
						...({
							'--canon-math-menu-cell': `${menu.cell.width}px`,
							'--canon-math-key-height': `${menu.cell.height}px`,
						} as CSSProperties),
						gridTemplateRows: `repeat(${Math.ceil(menu.keys.length / 3)}, ${menu.cell.height}px)`,
					}}
					ref={placing}
				>
					{menu.keys.map((item) => (
						<CanonMathKey
							key={item.label}
							face={item.face}
							family={menu.family}
							label={item.label}
							onClick={() =>
								type(
									item.key,
									menu.page,
								)
							}
							role="menuitem"
						/>
					))}
				</div>
			)}
		</div>
	);
}
