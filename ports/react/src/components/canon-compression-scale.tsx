import { useCallback, type CSSProperties, type HTMLAttributes } from 'react';
import {
	barLabel,
	compressionScale,
	labelSpare,
} from '@canon/lib/compression.ts';
import { springEasing } from '@canon/lib/motion.ts';
import CanonBar from './canon-bar.tsx';
import CanonFigure from './canon-figure.tsx';
import CanonLoader from './canon-loader.tsx';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-compression-scale.css';

export interface CanonCompressionScaleProps extends Omit<
	HTMLAttributes<HTMLDivElement>,
	'children'
> {
	/** The original's size in bytes; 0 before a file. */
	before: number;
	/** The result's size in bytes; 0 before a result. */
	after: number;
	/** The result bar's label. */
	format: string;
	/** Shows the loader beside the figure. */
	working?: boolean;
}

// the iOS bar spring: 0.6 s, damping 0.7
const easing = springEasing(0.7);

interface BarProps {
	label: string;
	bytes: number;
	share: number;
	fill: string;
	/** Label colour inside the fill. */
	ink: string;
}

function Bar({ label, bytes, share, fill, ink }: BarProps) {
	const text = barLabel(label, bytes);
	// the label sits inside the fill when it fits with 20 px to spare, else after it
	const place = useCallback(
		(bar: HTMLDivElement) => {
			const shown = bar.querySelector<HTMLElement>(
				'.canon-compression-scale-label',
			)!;
			const update = () =>
				bar.toggleAttribute(
					'data-inside',
					bar.clientWidth * share >=
						shown.offsetWidth + labelSpare,
				);
			update();
			const observer = new ResizeObserver(update);
			observer.observe(bar);
			return () => observer.disconnect();
		},
		// the label text changes its width
		// eslint-disable-next-line react-hooks/exhaustive-deps
		[share, text],
	);
	return (
		<div
			className="canon-compression-scale-bar"
			style={
				{
					'--canon-compression-scale-share':
						Math.min(Math.max(share, 0), 1),
					'--canon-compression-scale-ink': ink,
				} as CSSProperties
			}
			ref={place}
		>
			<CanonBar
				share={share}
				fill={fill}
				track="transparent"
			/>
			<span className="canon-compression-scale-label">
				{text}
			</span>
		</div>
	);
}

const colour = (grew: boolean) =>
	grew ? 'var(--canon-destructive)' : 'var(--canon-primary)';

/** Two bars to one scale, the original's bytes over the result's, with the saving as a figure. */
export default function CanonCompressionScale({
	before,
	after,
	format,
	working,
	className,
	style,
	...rest
}: CanonCompressionScaleProps) {
	const scale = compressionScale(before, after);
	return (
		<div
			className={cx('canon-compression-scale', className)}
			style={
				{
					'--canon-compression-scale-easing':
						easing,
					...style,
				} as CSSProperties
			}
			{...rest}
		>
			<div className="canon-compression-scale-top">
				{working && (
					<CanonLoader
						className="canon-compression-scale-loader"
						cell={5}
						gap={1}
					/>
				)}
				<CanonFigure
					text={scale.figure}
					unit={scale.unit}
					colour={colour(scale.grew)}
				/>
			</div>
			<Bar
				label="Original"
				bytes={before}
				share={1}
				fill="var(--canon-muted)"
				ink="var(--canon-foreground)"
			/>
			<Bar
				label={format}
				bytes={scale.known ? after : 0}
				share={scale.share}
				fill={colour(scale.grew)}
				ink="var(--canon-primary-foreground)"
			/>
		</div>
	);
}
