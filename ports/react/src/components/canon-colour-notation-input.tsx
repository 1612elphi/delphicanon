import { useEffect, useRef, useState, type HTMLAttributes } from 'react';
import { hex, parseColour, parseHex, type Rgb } from '@canon/lib/colour.ts';
import { cx } from '../lib/class-names.ts';
import { Pipette } from '../lib/control-icons.tsx';
import { useLatest } from '../lib/refs.ts';
import CanonButton from './canon-button.tsx';
import CanonRule from './canon-rule.tsx';
import CanonTextCell from './canon-text-cell.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-colour-notation-input.css';

export interface CanonColourNotationInputProps extends HTMLAttributes<HTMLDivElement> {
	/** Shown as hex while the field is not being typed in. */
	colour?: Rgb;
	/** A formatted value shown instead of `colour`'s hex. */
	text?: string;
	/** A picked colour, and a typed one read by the default `parse`. */
	onColour?: (colour: Rgb) => void;
	/**
	 * Reads typed text and uses it; false turns the text red. The default
	 * reads any notation `parseColour` knows and passes it to `onColour`.
	 */
	parse?: (text: string) => boolean;
	placeholder?: string;
	/** Id of the element that names the field, such as a row title. */
	labelledBy?: string;
	label?: string;
}

/** Typed text is read after this pause, on Return, and when the field loses focus. */
export const typingPauseMs = 400;

interface EyeDropperResult {
	sRGBHex: string;
}

type EyeDropperWindow = Window & {
	EyeDropper?: new () => { open(): Promise<EyeDropperResult> };
};

/**
 * A colour typed in any notation beside an eyedropper cell. The eyedropper
 * is the browser's EyeDropper and is left out where the browser has none.
 */
export default function CanonColourNotationInput({
	colour,
	text,
	onColour,
	parse: parseArg,
	placeholder,
	labelledBy,
	label,
	className,
	...rest
}: CanonColourNotationInputProps) {
	// the typed text holds until what is shown changes
	const [typed, setTyped] = useState<{ text: string; over: string }>();
	const [fails, setFails] = useState(false);
	const [focused, setFocused] = useState(false);
	const [hasEyedropper] = useState(() => 'EyeDropper' in window);
	const typing = useRef<number>(undefined);

	const shown = text ?? (colour ? hex(colour) : '');
	const value =
		typed && (focused || typed.over === shown) ? typed.text : shown;
	const failing = fails && value === typed?.text;

	const parse = (text: string): boolean => {
		if (parseArg) return parseArg(text);
		const colour = parseColour(text);
		if (colour) onColour?.(colour);
		return colour !== undefined;
	};

	const read = () => {
		window.clearTimeout(typing.current);
		if (typed === undefined) return;
		setFails(!parse(typed.text) && typed.text.trim() !== '');
	};
	const latest = useLatest({ read });

	useEffect(() => () => window.clearTimeout(typing.current), []);

	const type = (text: string) => {
		setTyped({ text, over: shown });
		setFails(false);
		window.clearTimeout(typing.current);
		typing.current = window.setTimeout(
			() => latest.current.read(),
			typingPauseMs,
		);
	};

	const leave = () => {
		setFocused(false);
		read();
		if (typed) setTyped({ ...typed, over: shown });
	};

	const pick = async () => {
		const { EyeDropper } = window as EyeDropperWindow;
		if (!EyeDropper) return;
		try {
			const { sRGBHex } = await new EyeDropper().open();
			const picked = parseHex(sRGBHex);
			if (picked) onColour?.(picked);
		} catch {
			// Escape closes the eyedropper with an AbortError
		}
	};

	return (
		<div
			className={cx('canon-colour-notation-input', className)}
			{...rest}
		>
			<CanonTextCell
				className={cx(
					'canon-colour-notation-input-field',
					failing &&
						'canon-colour-notation-input--fails',
				)}
				value={value}
				placeholder={
					placeholder
						? placeholder
						: 'oklch(0.64 0.15 264)'
				}
				onChange={type}
				spellCheck={false}
				autoComplete="off"
				autoCapitalize="off"
				aria-labelledby={labelledBy}
				aria-label={label}
				aria-invalid={failing ? 'true' : undefined}
				onFocus={() => setFocused(true)}
				onBlur={leave}
			/>
			{hasEyedropper && (
				<>
					<CanonRule vertical />
					<CanonButton
						kind="cell"
						icon={<Pipette />}
						label="Colour"
						onClick={() => void pick()}
					/>
				</>
			)}
		</div>
	);
}
