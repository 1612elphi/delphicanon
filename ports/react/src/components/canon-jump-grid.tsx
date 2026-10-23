import { useCallback, useState, type Ref } from 'react';
import { appearDelay, jumpColumns } from '@canon/lib/jump.ts';
import { reducedMotion, springEasing } from '@canon/lib/motion.ts';
import {
	CanonDialogBase,
	type CanonDialogClose,
	type CanonDialogProps,
} from './canon-dialog.tsx';
import CanonGrid from './canon-grid.tsx';
import { press } from '../lib/press.ts';
import { cx } from '../lib/class-names.ts';
import { useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-jump-grid.css';

export interface CanonJumpSection {
	title: string;
	/** Under the title, as a count of the group's items. */
	detail?: string;
}

export interface CanonJumpGridProps extends Omit<
	CanonDialogProps,
	| 'title'
	| 'message'
	| 'alert'
	| 'dismissable'
	| 'header'
	| 'children'
	| 'footer'
	| 'onClose'
> {
	open: boolean;
	sections: CanonJumpSection[];
	/** The lit tile: the group in view. It takes focus when the grid opens. */
	current?: number;
	/** The dialog's accessible name; default Sections. */
	label?: string;
	/** A tile was picked; called after the grid has closed and focus has returned. */
	onPick?: (index: number) => void;
	/** Every close. The owner sets `open` false here. */
	onClose?: () => void;
	ref?: Ref<HTMLDialogElement>;
}

// iOS crossDissolve: no scale
const fade = (): Keyframe[] => [{ opacity: 0 }, { opacity: 1 }];

const tileSpring = springEasing(0.7);

function Tile({
	section,
	index,
	count,
	current,
	close,
}: {
	section: CanonJumpSection;
	index: number;
	count: number;
	current: number | undefined;
	close: CanonDialogClose;
}) {
	const lit = index === current;
	// showModal reads the attribute
	const appear = useCallback(
		(tile: HTMLButtonElement | null) => {
			if (!tile) return;
			tile.toggleAttribute('autofocus', lit);
			if (reducedMotion()) return;
			tile.animate(
				[
					{
						opacity: 0,
						transform: 'scale(0.8) rotate(-0.05rad)',
					},
					{ opacity: 1, transform: 'none' },
				],
				{
					duration: 450,
					delay: appearDelay(
						index,
						count,
						current ?? 0,
					),
					easing: tileSpring,
					fill: 'backwards',
				},
			);
		},
		[lit, index, count, current],
	);
	return (
		<button
			type="button"
			className={cx(
				'canon-jump-grid-tile',
				lit && 'canon-jump-grid-tile--lit',
			)}
			aria-current={lit ? 'true' : undefined}
			ref={useRefs(press, appear)}
			onClick={() => close(String(index))}
		>
			<span className="canon-jump-grid-title">
				{section.title}
			</span>
			{section.detail && (
				<span className="canon-jump-grid-detail">
					{section.detail}
				</span>
			)}
		</button>
	);
}

/**
 * The Windows Phone jump list: every group of a long list as a tile over
 * the page, the group in view lit. A pick closes it and reports the group;
 * a click beside the tiles or Escape closes it.
 */
export default function CanonJumpGrid({
	open,
	sections,
	current,
	label,
	onPick,
	onClose,
	className,
	...rest
}: CanonJumpGridProps) {
	const [columns, setColumns] = useState(() =>
		typeof window === 'undefined'
			? 2
			: jumpColumns(window.innerWidth),
	);

	const measure = useCallback((holder: HTMLDivElement) => {
		const observer = new ResizeObserver(([entry]) => {
			setColumns(jumpColumns(entry?.contentRect.width ?? 0));
		});
		observer.observe(holder.closest('dialog') ?? holder);
		return () => observer.disconnect();
	}, []);

	const closed = (value: string) => {
		onClose?.();
		if (value !== '') onPick?.(Number(value));
	};

	return (
		<CanonDialogBase
			kindClasses="canon-dialog"
			keyframes={fade}
			className={cx('canon-jump-grid', className)}
			aria-label={label || 'Sections'}
			open={open}
			onClose={closed}
			{...rest}
		>
			{(close) => (
				<div
					className="canon-jump-grid-holder"
					ref={measure}
					onClick={(event) => {
						if (
							!(
								event.target as Element
							).closest(
								'.canon-jump-grid-tile',
							)
						)
							close();
					}}
				>
					<CanonGrid columns={columns} boxed>
						{sections.map(
							(section, index) => (
								<Tile
									key={
										index
									}
									section={
										section
									}
									index={
										index
									}
									count={
										sections.length
									}
									current={
										current
									}
									close={
										close
									}
								/>
							),
						)}
					</CanonGrid>
				</div>
			)}
		</CanonDialogBase>
	);
}
