import {
	useCallback,
	type CSSProperties,
	type HTMLAttributes,
	type Ref,
} from 'react';
import { hex, takesBlackInk, type Rgb } from '@canon/lib/colour.ts';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-loupe.css';

export type CanonLoupePixels =
	ImageData | ImageBitmap | HTMLCanvasElement | HTMLImageElement;

export interface CanonLoupeProps extends HTMLAttributes<HTMLDivElement> {
	/** The pixels around the sample point, one canvas pixel each, the sample in the middle. */
	pixels?: CanonLoupePixels;
	/** The sampled colour: the frame, and the ground behind missing pixels. */
	colour: Rgb;
	ref?: Ref<HTMLDivElement>;
}

/** 31 px across when no pixels are given, as on iOS. */
const defaultCount = 31;

/**
 * The pixels around a sample point, magnified without smoothing, framed in
 * the sampled colour. Place it with `frame` from `lib/loupe.ts`; it takes
 * no pointer input.
 */
export default function CanonLoupe({
	pixels,
	colour,
	className,
	style,
	...rest
}: CanonLoupeProps) {
	const draw = useCallback(
		(canvas: HTMLCanvasElement | null) => {
			const context = canvas?.getContext('2d');
			if (!canvas || !context) return;
			if (!pixels) {
				context.clearRect(
					0,
					0,
					canvas.width,
					canvas.height,
				);
				return;
			}
			canvas.width = pixels.width;
			canvas.height = pixels.height;
			if (pixels instanceof ImageData)
				context.putImageData(pixels, 0, 0);
			else context.drawImage(pixels, 0, 0);
		},
		[pixels],
	);

	return (
		<div
			className={cx('canon-loupe', className)}
			style={
				{
					'--canon-loupe-colour': hex(colour),
					'--canon-loupe-ink': takesBlackInk(
						colour,
					)
						? 'var(--canon-loupe-ink-dark)'
						: 'var(--canon-loupe-ink-light)',
					'--canon-loupe-count':
						pixels?.width || defaultCount,
					...style,
				} as CSSProperties
			}
			aria-hidden="true"
			{...rest}
		>
			<canvas className="canon-loupe-pixels" ref={draw} />
			<div className="canon-loupe-centre" />
		</div>
	);
}
