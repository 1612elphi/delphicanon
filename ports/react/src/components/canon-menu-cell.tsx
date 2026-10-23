import { useState, type HTMLAttributes, type Ref } from 'react';
import { cx } from '../lib/class-names.ts';
import { ChevronsUpDown } from '../lib/control-icons.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-menu-cell.css';

export interface CanonMenuCellProps extends Omit<
	HTMLAttributes<HTMLDivElement>,
	'onChange' | 'children'
> {
	items: string[];
	/** Undefined shows the placeholder: a value set elsewhere that matches no choice. */
	selected?: number;
	/** Default an em dash. */
	placeholder?: string;
	labelledBy?: string;
	label?: string;
	disabled?: boolean;
	onChange?: (index: number) => void;
	ref?: Ref<HTMLDivElement>;
}

/**
 * A flush cell that shows one choice and opens the system menu of all of
 * them: a native select laid invisibly over the cell.
 */
export default function CanonMenuCell({
	items,
	selected: selectedArg,
	placeholder = '—',
	labelledBy,
	label,
	disabled,
	onChange,
	className,
	...rest
}: CanonMenuCellProps) {
	const [picked, setPicked] = useState<{
		index: number;
		over: number | undefined;
	}>();
	const selected =
		picked && picked.over === selectedArg
			? picked.index
			: selectedArg;
	const title = selected === undefined ? undefined : items[selected];

	return (
		<div
			className={cx(
				'canon-menu-cell',
				disabled && 'canon-menu-cell--disabled',
				className,
			)}
			{...rest}
		>
			<span className="canon-menu-cell-title">
				{title || placeholder}
			</span>
			<span
				className="canon-menu-cell-icon"
				aria-hidden="true"
			>
				<ChevronsUpDown />
			</span>
			<select
				className="canon-menu-cell-select"
				aria-labelledby={labelledBy}
				aria-label={label}
				disabled={disabled}
				value={title ? String(selected) : ''}
				onChange={(event) => {
					const index = Number(
						event.target.value,
					);
					if (index === selected) return;
					setPicked({ index, over: selectedArg });
					onChange?.(index);
				}}
			>
				{!title && (
					<option value="" disabled hidden>
						{placeholder}
					</option>
				)}
				{items.map((choice, index) => (
					<option
						key={index}
						value={String(index)}
					>
						{choice}
					</option>
				))}
			</select>
		</div>
	);
}
