import {
	useCallback,
	useState,
	type CSSProperties,
	type HTMLAttributes,
} from 'react';
import { cx } from '../lib/class-names.ts';
import { useLatest } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-canvas.css';

export interface CanonCanvasProps extends HTMLAttributes<HTMLDivElement> {
	/** Fixed height of the band in px, rules included. */
	height?: number;
	/** Width over height of the content; used when `height` is not set. */
	aspect?: number;
	/** Caps the band's height in a wide column; the content letterboxes itself. */
	maxHeight?: number;
	/** never: always an edge-to-edge band. unlessWide: a band beside a sidebar, a framed box everywhere else. */
	boxing?: 'never' | 'unlessWide';
	/** CSS colour behind the content; default the card colour. */
	background?: string;
	/** Tiles `--canon-pattern` faintly under the content. A CanonSplit banner always has it. */
	pattern?: boolean;
	/**
	 * Takes the band's height from the content's own height at the column's
	 * width, plus the rules; content with no height hides the band.
	 */
	fitting?: boolean;
	/** With `fitting`: a change of the content's height at the same width animates the band. */
	animated?: boolean;
}

/**
 * Edge-to-edge band for a picture, a preview or a drawing surface, ruled
 * above and below. As a page section it spans its column; as a CanonSplit
 * banner it spans every column. Place it between blocks of CanonRows.
 */
export default function CanonCanvas({
	height,
	aspect,
	maxHeight,
	boxing,
	background,
	pattern,
	fitting,
	animated,
	className,
	style,
	children,
	...rest
}: CanonCanvasProps) {
	const [fitted, setFitted] = useState<number>();
	const [eases, setEases] = useState(false);
	const animates = useLatest(animated);

	const fit = useCallback(
		(element: HTMLDivElement) => {
			let width: number | undefined;
			const observer = new ResizeObserver(([entry]) => {
				const box = entry?.borderBoxSize[0];
				if (!box) return;
				setEases(
					Boolean(animates.current) &&
						box.inlineSize === width,
				);
				width = box.inlineSize;
				setFitted(box.blockSize);
			});
			observer.observe(element);
			return () => observer.disconnect();
		},
		[animates],
	);

	const vars: Record<string, string> = {
		'--canon-canvas-natural':
			height !== undefined
				? `${height}px`
				: `calc(100cqw / ${aspect ?? 1} + 2 * var(--canon-frame))`,
	};
	if (fitting && fitted !== undefined)
		vars['--canon-canvas-fitted'] = `${fitted}px`;
	if (maxHeight !== undefined)
		vars['--canon-canvas-max'] = `${maxHeight}px`;
	if (background) vars['--canon-canvas-background'] = background;

	return (
		<div
			className={cx(
				'canon-canvas',
				boxing === 'unlessWide' &&
					'canon-canvas--unless-wide',
				pattern && 'canon-canvas--pattern',
				fitting && 'canon-canvas--fitting',
				fitting &&
					fitted === 0 &&
					'canon-canvas--collapsed',
				eases && 'canon-canvas--eases',
				className,
			)}
			style={{ ...vars, ...style } as CSSProperties}
			data-canon-height={height}
			data-canon-aspect={aspect}
			{...rest}
		>
			<div className="canon-canvas-content">
				{fitting ? (
					<div
						className="canon-canvas-fit"
						ref={fit}
					>
						{children}
					</div>
				) : (
					children
				)}
			</div>
		</div>
	);
}
