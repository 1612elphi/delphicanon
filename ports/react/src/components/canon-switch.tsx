import { useState, type InputHTMLAttributes, type Ref } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-switch.css';

export interface CanonSwitchProps extends Omit<
	InputHTMLAttributes<HTMLInputElement>,
	'onChange' | 'type' | 'checked'
> {
	on?: boolean;
	disabled?: boolean;
	onChange?: (on: boolean) => void;
	ref?: Ref<HTMLInputElement>;
}

/** An on/off switch: a native checkbox with the switch role. */
export default function CanonSwitch({
	on: onArg,
	disabled,
	onChange,
	className,
	...rest
}: CanonSwitchProps) {
	// a flip holds until the on prop changes
	const [flipped, setFlipped] = useState<{
		on: boolean;
		over: boolean | undefined;
	}>();
	const on =
		flipped && flipped.over === onArg
			? flipped.on
			: (onArg ?? false);

	return (
		<input
			type="checkbox"
			role="switch"
			className={cx('canon-switch', className)}
			checked={on}
			aria-checked={on}
			disabled={disabled}
			{...rest}
			onChange={(event) => {
				const next = event.target.checked;
				setFlipped({ on: next, over: onArg });
				onChange?.(next);
			}}
		/>
	);
}
