import type { CSSProperties, HTMLAttributes } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-detent-wheel-row.css';

export interface CanonDetentWheelRowProps extends HTMLAttributes<HTMLDivElement> {
	/** From CanonDetentWheel's children: 1 on the centre line, 0 a row or more away. */
	focus: number;
}

/** A centred label for a CanonDetentWheel row that brightens as it nears the centre line. */
export default function CanonDetentWheelRow({
	focus,
	className,
	style,
	...rest
}: CanonDetentWheelRowProps) {
	return (
		<div
			className={cx('canon-detent-wheel-row', className)}
			style={
				{
					'--canon-detent-focus': focus,
					...style,
				} as CSSProperties
			}
			{...rest}
		/>
	);
}
