import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { modifier } from 'ember-modifier';
import press from '../modifiers/canon-press.ts';
import { repeatTiming } from './canon-button.gts';
import CanonMathView from './canon-math-view.gts';
import type { Key } from '../lib/math/expression.ts';
import {
	familyOf,
	keyHeights,
	label,
	labelShare,
	spoken,
	type Family,
} from '../lib/math/keypad.ts';
import { canvasMetrics } from '../lib/math/measure.ts';
import type { Box } from '../lib/math/typeset.ts';
import '../styles/tokens.css';
import './canon-math-key.css';
import { ChevronUp as chevronUp } from 'lucide-static';
import CanonIcon from './canon-icon.gts';

export interface CanonMathKeySignature {
	Args: {
		/** The key typed; gives the label, the family and the spoken name. */
		key?: Key;
		/** The letter the derivative key shows; default x. */
		variable?: string;
		/** Label size in px before `scale`; default 24, the regular key's. */
		size?: number;
		scale?: number;
		/** A label set elsewhere, instead of the key's. */
		face?: Box;
		family?: Family;
		/** Accessible name; default the key's spoken name. */
		label?: string;
		/** Marks a key that opens a submenu with a chevron. */
		menu?: boolean;
		/** Holding repeats the tap, as delete does. */
		repeats?: boolean;
		onClick?: () => void;
	};
	Blocks: { default: [] };
	Element: HTMLButtonElement;
}

/** Travel in px that turns a press into a drag. */
export const slop = 10;

const Chevron = <template>
	<span class="canon-math-key-chevron"><CanonIcon
			@svg={{chevronUp}}
		/></span>
</template>;

/**
 * One key: a flush cell in its family's colours with one label, set large
 * and centred (CanonMathKeyView). A tap does one thing; a drag past the slop
 * does nothing. Outside the keypad it is the insert cell
 * (`CanonMathKeypad.cell`).
 */
export default class CanonMathKey extends Component<CanonMathKeySignature> {
	#start?: { x: number; y: number };
	#moved = false;
	#held = false;
	#didRepeat = false;
	#timer?: number;

	get family(): Family {
		return (
			this.args.family ??
			(this.args.key ? familyOf(this.args.key) : 'digit')
		);
	}

	get face(): Box | undefined {
		if (this.args.face) return this.args.face;
		if (!this.args.key) return undefined;
		const size =
			this.args.size ??
			Math.round(keyHeights.regular * labelShare);
		return label(
			this.args.key,
			this.args.variable ?? 'x',
			size * (this.args.scale ?? 1),
			canvasMetrics,
		);
	}

	get label() {
		return (
			this.args.label ??
			(this.args.key
				? spoken(
						this.args.key,
						this.args.variable ?? 'x',
					)
				: undefined)
		);
	}

	@action click() {
		if (this.#moved || this.#didRepeat) {
			this.#didRepeat = false;
			return;
		}
		this.args.onClick?.();
	}

	stroke = modifier((button: HTMLButtonElement) => {
		const down = (event: PointerEvent) => {
			this.#start = { x: event.clientX, y: event.clientY };
			this.#moved = false;
			this.#didRepeat = false;
			if (!this.args.repeats || event.button !== 0) return;
			this.#held = true;
			this.#schedule(repeatTiming.delay, 0);
		};
		const move = (event: PointerEvent) => {
			if (!this.#start || this.#moved) return;
			const travel = Math.hypot(
				event.clientX - this.#start.x,
				event.clientY - this.#start.y,
			);
			if (travel > slop && !this.#didRepeat) {
				this.#moved = true;
				this.#letGo();
			}
		};
		const up = () => this.#letGo();
		const ends = [
			'pointerup',
			'pointercancel',
			'lostpointercapture',
		] as const;
		button.addEventListener('pointerdown', down);
		button.addEventListener('pointermove', move);
		ends.forEach((type) => button.addEventListener(type, up));
		return () => {
			this.#letGo();
			button.removeEventListener('pointerdown', down);
			button.removeEventListener('pointermove', move);
			ends.forEach((type) =>
				button.removeEventListener(type, up),
			);
		};
	});

	#letGo() {
		this.#held = false;
		window.clearTimeout(this.#timer);
	}

	#schedule(seconds: number, count: number) {
		window.clearTimeout(this.#timer);
		this.#timer = window.setTimeout(() => {
			if (!this.#held) return;
			this.#didRepeat = true;
			this.args.onClick?.();
			this.#schedule(
				count < 10
					? repeatTiming.interval
					: repeatTiming.fast,
				count + 1,
			);
		}, seconds * 1000);
	}

	willDestroy() {
		super.willDestroy();
		window.clearTimeout(this.#timer);
	}

	<template>
		<button
			type="button"
			class="canon-math-key canon-math-key--{{this.family}}"
			aria-label={{this.label}}
			aria-haspopup={{if @menu "true"}}
			{{press}}
			{{this.stroke}}
			{{on "click" this.click}}
			...attributes
		>
			<span class="canon-math-key-face">
				{{#if (has-block)}}
					{{yield}}
				{{else if this.face}}
					<CanonMathView
						@box={{this.face}}
						@mono={{true}}
						aria-hidden="true"
					/>
				{{/if}}
				{{#if @menu}}<Chevron />{{/if}}
			</span>
		</button>
	</template>
}
