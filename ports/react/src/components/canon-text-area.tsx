import type { CSSProperties, Ref, TextareaHTMLAttributes } from 'react';
import { cx } from '../lib/class-names.ts';
import { useRefs } from '../lib/refs.ts';
import { useShownValue } from '../lib/shown-value.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-text-area.css';

export interface CanonTextAreaProps extends Omit<
	TextareaHTMLAttributes<HTMLTextAreaElement>,
	'value' | 'onChange' | 'children'
> {
	value?: string;
	placeholder?: string;
	/** Fixed height in px; default 200. The text scrolls inside it. */
	height?: number;
	/** Called for typed edits, not for a new `value`. */
	onChange?: (value: string) => void;
	ref?: Ref<HTMLTextAreaElement>;
}

/** Multi-line monospaced input, wrapping, with its own scrolling. */
export default function CanonTextArea({
	value,
	placeholder,
	height,
	onChange,
	className,
	style,
	ref,
	...rest
}: CanonTextAreaProps) {
	// a model echo must not replace the text being typed
	const area = useShownValue<HTMLTextAreaElement>(value || '', true);
	const size: CSSProperties =
		height === undefined ? {} : { blockSize: `${height}px` };
	return (
		<textarea
			className={cx('canon-text-area', className)}
			placeholder={placeholder}
			autoComplete="off"
			autoCapitalize="off"
			spellCheck="false"
			style={{ ...size, ...style }}
			{...rest}
			ref={useRefs(area, ref)}
			onInput={(event) =>
				onChange?.(event.currentTarget.value)
			}
		/>
	);
}
