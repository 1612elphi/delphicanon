import {
	useLayoutEffect,
	useRef,
	type ButtonHTMLAttributes,
	type CSSProperties,
	type Ref,
} from 'react';
import { cx } from '../lib/class-names.ts';
import { Copy } from '../lib/control-icons.tsx';
import { press } from '../lib/press.ts';
import { useRefs } from '../lib/refs.ts';
import { canonToast } from '../lib/toast-store.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-value-line.css';

export type CanonValueLineLayout = 'beside' | 'above' | 'wrapping' | 'numbered';

export interface CanonValueLineProps extends Omit<
	ButtonHTMLAttributes<HTMLButtonElement>,
	'value'
> {
	label: string;
	/** Null or undefined shows a dash and turns copying off. */
	value?: string | null;
	/**
	 * beside: the label in a column `labelWidth` wide, the value on one line.
	 * above: the label over the value. wrapping: the label as wide as it is,
	 * the value wrapping by character. numbered: a list index as the label.
	 */
	layout?: CanonValueLineLayout;
	/** Width of the label column in px for `beside`; fit it to the longest label among sibling lines. */
	labelWidth?: number;
	/** For `numbered`: a long value wraps by character instead of being cut off. */
	wraps?: boolean;
	/** Seconds after a change before the new value fades in; unset changes it at once. */
	fadeDelay?: number;
	/** Marks the chosen line of a list. */
	lit?: boolean;
	/** CSS colour for each character of the value; unset sets the value in one colour. */
	tint?: (character: string) => string;
	disabled?: boolean;
	ref?: Ref<HTMLButtonElement>;
}

const dash = '—';

/** The old value stays for the delay, then crossfades to the new one. */
function fade(
	element: HTMLElement,
	before: string | undefined,
	text: string,
	delay: number | undefined,
) {
	if (delay === undefined || before === undefined || before === text)
		return;
	if (window.matchMedia('(prefers-reduced-motion: reduce)').matches)
		return;
	const ghost = document.createElement('span');
	ghost.className = 'canon-value-line-value canon-value-line-ghost';
	ghost.textContent = before;
	ghost.setAttribute('aria-hidden', 'true');
	Object.assign(ghost.style, {
		insetInlineStart: `${element.offsetLeft}px`,
		insetBlockStart: `${element.offsetTop}px`,
		inlineSize: `${element.offsetWidth}px`,
	});
	element.after(ghost);
	const duration =
		parseFloat(
			getComputedStyle(element).getPropertyValue(
				'--canon-value-line-fade',
			),
		) || 250;
	const timing = { duration, delay: delay * 1000 };
	element.animate({ opacity: [0, 1] }, { ...timing, fill: 'backwards' });
	ghost.animate({ opacity: [1, 0] }, { ...timing, fill: 'forwards' })
		.finished.catch(() => undefined)
		.finally(() => ghost.remove());
}

/** A name and a value in a flush cell; a tap copies the value and confirms with the toast. */
export default function CanonValueLine({
	label,
	value,
	layout = 'beside',
	labelWidth,
	wraps,
	fadeDelay,
	lit,
	tint,
	disabled,
	className,
	style,
	ref,
	...rest
}: CanonValueLineProps) {
	const shown = value ?? dash;
	const valueElement = useRef<HTMLSpanElement>(null);
	const shownBefore = useRef<string>(undefined);

	useLayoutEffect(() => {
		const before = shownBefore.current;
		shownBefore.current = shown;
		if (valueElement.current)
			fade(valueElement.current, before, shown, fadeDelay);
	}, [shown, fadeDelay]);

	return (
		<button
			type="button"
			className={cx(
				'canon-value-line',
				`canon-value-line--${layout}`,
				wraps && 'canon-value-line--wraps',
				lit && 'canon-value-line--lit',
				className,
			)}
			style={
				{
					'--canon-value-line-label': `${labelWidth ?? 48}px`,
					...style,
				} as CSSProperties
			}
			aria-label={
				layout === 'numbered'
					? shown
					: `${label} ${shown}`
			}
			aria-current={lit ? 'true' : undefined}
			disabled={disabled || value == null}
			onClick={() => void canonToast.copy(shown)}
			ref={useRefs(press, ref)}
			{...rest}
		>
			<span className="canon-value-line-label">{label}</span>
			<span
				className="canon-value-line-value"
				ref={valueElement}
			>
				{tint
					? [...shown].map((character, index) => (
							<span
								key={index}
								style={{
									color: tint(
										character,
									),
								}}
							>
								{character}
							</span>
						))
					: shown}
			</span>
			<span
				className="canon-value-line-glyph"
				aria-hidden="true"
			>
				<Copy />
			</span>
		</button>
	);
}
