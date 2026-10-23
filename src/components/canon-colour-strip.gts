import Component from '@glimmer/component';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import {
	formatColour,
	hex,
	type ColourFormat,
	type Rgb,
} from '../lib/colour.ts';
import press from '../modifiers/canon-press.ts';
import type CanonToastService from '../services/canon-toast.ts';
import CanonSwatch from './canon-swatch.gts';
import '../styles/tokens.css';
import './canon-colour-strip.css';

export interface CanonColourStripSignature {
	Args: {
		colour: Rgb;
		/** Shows these colours as swatches instead, each copying its hex on a tap. */
		palette?: Rgb[];
		/** Nearest colour name for a hex. */
		nameOf?: (hex: string) => string;
		/** The value shown and copied; default hex. */
		format?: ColourFormat;
	};
	Element: HTMLDivElement;
}

/**
 * A strip along the bottom of a colour picture: swatch, nearest name, the
 * colour in the primary format; a tap copies the value. Place it under the
 * picture inside the same canvas.
 */
export default class CanonColourStrip extends Component<CanonColourStripSignature> {
	@service('canon-toast') declare toast: CanonToastService;

	get value() {
		return formatColour(
			this.args.colour,
			this.args.format ?? 'hex',
		);
	}

	get name() {
		return this.args.nameOf?.(hex(this.args.colour));
	}

	get swatchStyle() {
		return htmlSafe(`background: ${hex(this.args.colour)}`);
	}

	get showsPalette() {
		return (this.args.palette?.length ?? 0) > 0;
	}

	copy = () => void this.toast.copy(this.value);

	<template>
		<div class="canon-colour-strip" ...attributes>
			{{#if this.showsPalette}}
				<div class="canon-colour-strip-palette">
					{{#each @palette as |colour|}}
						<CanonSwatch
							@colour={{colour}}
							@nameOf={{@nameOf}}
						/>
					{{/each}}
				</div>
			{{else}}
				<button
					type="button"
					class="canon-colour-strip-single"
					aria-label="{{this.name}} {{this.value}}"
					{{press}}
					{{on "click" this.copy}}
				>
					<span
						class="canon-colour-strip-swatch"
						style={{this.swatchStyle}}
					></span>
					<span class="canon-colour-strip-text">
						{{#if this.name}}
							<span
								class="canon-colour-strip-name"
							>{{this.name}}</span>
						{{/if}}
						<span
							class="canon-colour-strip-value"
						>{{this.value}}</span>
					</span>
				</button>
			{{/if}}
		</div>
	</template>
}
