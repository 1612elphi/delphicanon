import {
	useLayoutEffect,
	useRef,
	type CSSProperties,
	type HTMLAttributes,
	type Ref,
} from 'react';
import { changedFromEnd, leadingNumber } from '@canon/lib/figure.ts';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-figure.css';

export interface CanonFigureProps extends Omit<
	HTMLAttributes<HTMLDivElement>,
	'children'
> {
	text: string;
	/** Set smaller after the figure. */
	unit?: string;
	/** Font size in px; default 40. */
	size?: number;
	/** CSS colour; default the primary colour. A change fades. */
	colour?: string;
	/** Outline and soft shadow in this CSS colour, for a figure over a picture. */
	halo?: string;
	/** False shows a new text without rolling. */
	animated?: boolean;
	ref?: Ref<HTMLDivElement>;
}

const rollMs = 350;
const easing = 'cubic-bezier(0.2, 0.9, 0.3, 1)';

function still() {
	return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

/** Rebuilds the characters; changed ones roll in the direction the number moved. */
function roll(
	element: HTMLElement,
	text: string,
	before: string | undefined,
	animated: boolean,
) {
	element.replaceChildren(
		...[...text].map((char) => {
			const span = document.createElement('span');
			span.className = 'canon-figure-char';
			span.textContent = char;
			return span;
		}),
	);
	if (before === undefined || before === text || !animated || still())
		return;
	// up rolls new characters in from below
	const up = leadingNumber(text) >= leadingNumber(before) ? 1 : -1;
	const spans = [...element.children] as HTMLElement[];
	for (const { index, old } of changedFromEnd(before, text)) {
		const span = spans[index]!;
		span.animate(
			[
				{
					transform: `translateY(${up * 60}%)`,
					opacity: 0,
					filter: 'blur(2px)',
				},
				{
					transform: 'none',
					opacity: 1,
					filter: 'none',
				},
			],
			{ duration: rollMs, easing },
		);
		if (old === undefined) continue;
		const ghost = document.createElement('span');
		ghost.className = 'canon-figure-ghost';
		ghost.textContent = old;
		span.append(ghost);
		ghost.animate(
			[
				{
					transform: 'none',
					opacity: 1,
					filter: 'none',
				},
				{
					transform: `translateY(${-up * 60}%)`,
					opacity: 0,
					filter: 'blur(2px)',
				},
			],
			{ duration: rollMs, easing, fill: 'forwards' },
		).finished.then(
			() => ghost.remove(),
			() => ghost.remove(),
		);
	}
}

/** A calculated figure whose changed characters roll. */
export default function CanonFigure({
	text,
	unit,
	size = 40,
	colour,
	halo,
	animated = true,
	className,
	style,
	...rest
}: CanonFigureProps) {
	const chars = useRef<HTMLSpanElement>(null);
	const previous = useRef<string>(undefined);

	useLayoutEffect(() => {
		if (!chars.current) return;
		roll(chars.current, text, previous.current, animated);
		previous.current = text;
	}, [text, animated]);

	const vars: Record<string, string> = {
		'--canon-figure-size': `${size}px`,
	};
	if (colour) vars['--canon-figure-colour'] = colour;
	if (halo) {
		const edge = `0 0 1px ${halo}`;
		vars['textShadow'] =
			`${edge}, ${edge}, ${edge}, ${edge}, 0 3px 5px ${halo}`;
	}

	return (
		<div
			className={cx('canon-figure', className)}
			style={{ ...vars, ...style } as CSSProperties}
			{...rest}
		>
			<span className="canon-figure-said">
				{text}
				{unit}
			</span>
			<span
				className="canon-figure-text"
				aria-hidden="true"
				ref={chars}
			/>
			{unit && (
				<span
					className="canon-figure-unit"
					aria-hidden="true"
				>
					{unit}
				</span>
			)}
		</div>
	);
}
