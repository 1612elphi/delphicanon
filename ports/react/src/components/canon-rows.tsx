import type { HTMLAttributes } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-rows.css';

export interface CanonRowsProps extends HTMLAttributes<HTMLDivElement> {
	/** Draws the 2 px tool frame around the rows. */
	framed?: boolean;
}

/** Rows separated by hairlines: the gaps show the border colour. */
export default function CanonRows({
	framed,
	className,
	children,
	...rest
}: CanonRowsProps) {
	return (
		<div
			className={cx(
				'canon-rows',
				framed && 'canon-rows--framed',
				className,
			)}
			{...rest}
		>
			{children}
		</div>
	);
}
