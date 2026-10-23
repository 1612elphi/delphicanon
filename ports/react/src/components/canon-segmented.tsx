import { useState, type ReactNode } from 'react';
import CanonButton from './canon-button.tsx';
import CanonGrid, { type CanonGridProps } from './canon-grid.tsx';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';

export interface CanonSegmentedProps extends Omit<
	CanonGridProps,
	'onChange' | 'children'
> {
	/** Titles; with `icons`, what assistive technology reads. */
	items: string[];
	/** Cells that show a symbol instead of the title, one per item. */
	icons?: ReactNode[];
	selected?: number;
	disabled?: boolean;
	/** Indices of choices that cannot be taken now; they stay, greyed. */
	disabledIndices?: number[];
	onChange?: (index: number) => void;
}

/** Single selection from a flush grid of cells. */
export default function CanonSegmented({
	items,
	icons,
	selected: chosen,
	disabled,
	disabledIndices,
	onChange,
	className,
	...rest
}: CanonSegmentedProps) {
	// a pick holds until the selected prop changes
	const [picked, setPicked] = useState<{
		index: number;
		over: number | undefined;
	}>();
	const selected =
		picked && picked.over === chosen ? picked.index : (chosen ?? 0);

	const pick = (index: number) => {
		if (index === selected) return;
		setPicked({ index, over: chosen });
		onChange?.(index);
	};

	return (
		<CanonGrid
			className={cx('canon-segmented', className)}
			role="radiogroup"
			{...rest}
		>
			{items.map((title, index) => {
				const icon = icons?.[index];
				return (
					<CanonButton
						key={index}
						role="radio"
						aria-checked={
							index === selected
								? 'true'
								: 'false'
						}
						kind="segment"
						text={icon ? '' : title}
						icon={icon}
						label={title}
						selected={index === selected}
						disabled={
							disabled === true ||
							(disabledIndices?.includes(
								index,
							) ??
								false)
						}
						onClick={() => pick(index)}
					/>
				);
			})}
		</CanonGrid>
	);
}
