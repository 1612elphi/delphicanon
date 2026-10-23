import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import { hex, takesBlackInk, type Rgb } from '../lib/colour.ts';
import '../styles/tokens.css';
import './canon-loupe.css';

export type CanonLoupePixels =
	ImageData | ImageBitmap | HTMLCanvasElement | HTMLImageElement;

export interface CanonLoupeSignature {
	Args: {
		/** The pixels around the sample point, one canvas pixel each, the sample in the middle. */
		pixels?: CanonLoupePixels;
		/** The sampled colour: the frame, and the ground behind missing pixels. */
		colour: Rgb;
	};
	Element: HTMLDivElement;
}

/** 31 px across when no pixels are given, as on iOS. */
const defaultCount = 31;

/**
 * The pixels around a sample point, magnified without smoothing, framed in
 * the sampled colour. Place it with `frame` from `lib/loupe.ts`; it takes
 * no pointer input.
 */
export default class CanonLoupe extends Component<CanonLoupeSignature> {
	get count() {
		return this.args.pixels?.width || defaultCount;
	}

	get style() {
		const colour = hex(this.args.colour);
		const ink = takesBlackInk(this.args.colour)
			? 'var(--canon-loupe-ink-dark)'
			: 'var(--canon-loupe-ink-light)';
		return htmlSafe(
			`--canon-loupe-colour: ${colour}; --canon-loupe-ink: ${ink}; --canon-loupe-count: ${this.count}`,
		);
	}

	draw = modifier(
		(
			canvas: HTMLCanvasElement,
			[pixels]: [CanonLoupePixels | undefined],
		) => {
			const context = canvas.getContext('2d');
			if (!context) return;
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
	);

	<template>
		<div
			class="canon-loupe"
			style={{this.style}}
			aria-hidden="true"
			...attributes
		>
			<canvas
				class="canon-loupe-pixels"
				{{this.draw @pixels}}
			></canvas>
			<div class="canon-loupe-centre"></div>
		</div>
	</template>
}
