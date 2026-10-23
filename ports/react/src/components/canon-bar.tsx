import type { CSSProperties, HTMLAttributes } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-bar.css';

export interface CanonBarProps extends HTMLAttributes<HTMLDivElement> {
	/** Filled share of the width, 0 to 1. */
	share: number;
	/** CSS colour of the fill; default the primary colour. */
	fill?: string;
	/** CSS colour of the track; default the muted colour. */
	track?: string;
}

/** A bar filled from the leading edge. */
export default function CanonBar({
	share,
	fill,
	track,
	className,
	style,
	...rest
}: CanonBarProps) {
	const vars: Record<string, string | number> = {
		'--canon-bar-share': Math.min(Math.max(share, 0), 1),
	};
	if (fill) vars['--canon-bar-fill'] = fill;
	if (track) vars['--canon-bar-track'] = track;
	return (
		<div
			className={cx('canon-bar', className)}
			style={{ ...vars, ...style } as CSSProperties}
			{...rest}
		>
			<div className="canon-bar-fill" />
		</div>
	);
}
