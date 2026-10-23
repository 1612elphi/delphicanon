import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import {
	formatColour,
	hex,
	parseHex,
	type ColourFormat,
	type Rgb,
} from '../lib/colour.ts';
import press from '../modifiers/canon-press.ts';
import '../styles/tokens.css';
import './canon-colour-well.css';

export interface CanonColourWellSignature {
	Args: {
		/** Caption over the hex, and the swatch's accessible name. */
		label?: string;
		colour: Rgb;
		/** The app's primary colour format, echoed under the hex unless it is hex. */
		format?: ColourFormat;
		onChange?: (colour: Rgb) => void;
	};
	Element: HTMLDivElement;
}

/** Swatch cell that opens the system picker, beside a hex field. */
export default class CanonColourWell extends Component<CanonColourWellSignature> {
	get hex() {
		return hex(this.args.colour);
	}

	get digits() {
		return this.hex.slice(1);
	}

	get swatchStyle() {
		return htmlSafe(`background: ${this.hex}`);
	}

	get echo() {
		const { format } = this.args;
		return format && format !== 'hex'
			? formatColour(this.args.colour, format)
			: undefined;
	}

	picked = (event: Event) => {
		const colour = parseHex(
			(event.target as HTMLInputElement).value,
		);
		if (colour) this.args.onChange?.(colour);
	};

	typed = (event: Event) => {
		const field = event.target as HTMLInputElement;
		const digits = field.value.replace(/[^\da-f]/gi, '');
		const colour =
			digits.length === 6 ? parseHex(digits) : undefined;
		if (colour && hex(colour) !== this.hex)
			this.args.onChange?.(colour);
		field.value = colour ? hex(colour).slice(1) : this.digits;
	};

	done = (event: KeyboardEvent) => {
		if (event.key === 'Enter')
			(event.target as HTMLInputElement).blur();
	};

	<template>
		<div class="canon-colour-well" ...attributes>
			<div
				class="canon-colour-well-swatch"
				style={{this.swatchStyle}}
				{{press}}
			>
				<input
					type="color"
					value={{this.hex}}
					aria-label={{if @label @label "Colour"}}
					{{on "input" this.picked}}
				/>
			</div>
			<div class="canon-colour-well-cell">
				{{#if @label}}
					<span
						class="canon-colour-well-label"
					>{{@label}}</span>
				{{/if}}
				<span class="canon-colour-well-field">
					<span
						class="canon-colour-well-hash"
						aria-hidden="true"
					>#</span>
					<input
						type="text"
						value={{this.digits}}
						placeholder="000000"
						maxlength="7"
						spellcheck="false"
						autocomplete="off"
						autocapitalize="off"
						aria-label={{if
							@label
							@label
							"Hex"
						}}
						{{on "change" this.typed}}
						{{on "keydown" this.done}}
					/>
				</span>
				{{#if this.echo}}
					<span
						class="canon-colour-well-echo"
					>{{this.echo}}</span>
				{{/if}}
			</div>
		</div>
	</template>
}
