import type { HTMLAttributes, Ref } from 'react';
import CanonStepper from './canon-stepper.tsx';
import { cx } from '../lib/class-names.ts';
import { useShownValue } from '../lib/shown-value.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-big-number-field.css';

export interface CanonBigNumberFieldProps extends Omit<
	HTMLAttributes<HTMLDivElement>,
	'onInput' | 'children'
> {
	/** The field's text; the tool parses it and sets it. */
	value?: string;
	placeholder?: string;
	/** Centred under the number. */
	unit?: string;
	/** Called with -1 or 1 by the step buttons (repeating while held) and the arrow keys. */
	onStep: (direction: -1 | 1) => void;
	/** Called on every edit with the typed text. */
	onInput?: (text: string) => void;
	/** Typing ended: the field lost focus or Return was pressed. */
	onEndEditing?: () => void;
	labelledBy?: string;
	label?: string;
	disabled?: boolean;
	ref?: Ref<HTMLDivElement>;
}

/** A tool's main number, large and centred over its unit, between step buttons. */
export default function CanonBigNumberField({
	value,
	placeholder,
	unit,
	onStep,
	onInput,
	onEndEditing,
	labelledBy,
	label,
	disabled,
	className,
	...rest
}: CanonBigNumberFieldProps) {
	const field = useShownValue<HTMLInputElement>(value);
	return (
		<CanonStepper
			className={cx('canon-big-number-field', className)}
			onStep={onStep}
			disabled={disabled}
			{...rest}
		>
			<span className="canon-big-number-field-stack">
				<input
					type="text"
					className="canon-big-number-field-input"
					inputMode="decimal"
					enterKeyHint="done"
					autoComplete="off"
					spellCheck="false"
					placeholder={placeholder}
					aria-labelledby={labelledBy}
					aria-label={label}
					disabled={disabled}
					ref={field}
					onInput={(event) =>
						onInput?.(
							event.currentTarget
								.value,
						)
					}
					onKeyDown={(event) => {
						if (event.key === 'Enter')
							event.currentTarget.blur();
						if (
							event.key !==
								'ArrowUp' &&
							event.key !==
								'ArrowDown'
						)
							return;
						event.preventDefault();
						onStep(
							event.key === 'ArrowUp'
								? 1
								: -1,
						);
					}}
					onBlur={() => onEndEditing?.()}
				/>
				{unit && (
					<span className="canon-big-number-field-unit">
						{unit}
					</span>
				)}
			</span>
		</CanonStepper>
	);
}
