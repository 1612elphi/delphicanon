import type { HTMLAttributes } from 'react';
import CanonFigure from './canon-figure.tsx';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-dimension-line.css';

export {
	dimensionLine,
	dimensionLines,
	sheet,
	type Rect,
	type Size,
} from '@canon/lib/dimension-line.ts';

export interface CanonDimensionLineProps extends Omit<
	HTMLAttributes<HTMLSpanElement>,
	'children'
> {
	pixels: number;
	/** Turned a quarter, reading upwards, beside the leading side of what it measures. */
	down?: boolean;
	/** Muted rule and ticks, no figure: an empty picture keeps a loaded one's frame without stale sizes. */
	blank?: boolean;
}

/**
 * A measured span: a rule with end ticks along its bottom edge, the pixel
 * figure centred above it. Placed by the consumer with inset and size
 * properties (`dimensionLines` in `lib/dimension-line.ts`), before the turn.
 */
export default function CanonDimensionLine({
	pixels,
	down,
	blank,
	className,
	...rest
}: CanonDimensionLineProps) {
	return (
		<span
			className={cx(
				'canon-dimension-line',
				down && 'canon-dimension-line--down',
				blank && 'canon-dimension-line--blank',
				className,
			)}
			aria-hidden="true"
			{...rest}
		>
			{!blank && (
				<CanonFigure
					className="canon-dimension-line-figure"
					text={String(pixels)}
					unit="px"
					size={17}
					halo="var(--canon-muted)"
				/>
			)}
		</span>
	);
}
