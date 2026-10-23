import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { registerDestructor } from '@ember/destroyable';
import type Owner from '@ember/owner';
import type { TOC } from '@ember/component/template-only';
import CanonBigNumberField from '#src/components/canon-big-number-field.gts';
import CanonButton from '#src/components/canon-button.gts';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonNumberField from '#src/components/canon-number-field.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonSegmented from '#src/components/canon-segmented.gts';
import CanonSplit from '#src/components/canon-split.gts';
import press from '#src/modifiers/canon-press.ts';
import { clamp, parseInteger } from '#src/lib/number.ts';
import type CanonToastService from '#src/services/canon-toast.ts';
import Icon from '../../icon.gts';
import { baseRange, commonPx, convert, format, nudged, parse } from './rem.ts';
import Specimen from './specimen.gts';
import './px-to-rem.css';
import ruler from 'lucide-static/icons/ruler.svg?raw';
import copySvg from 'lucide-static/icons/copy.svg?raw';

export const tool = { title: 'PX to REM', group: 'Typography', icon: ruler };

// ?pxValue=<number>: the iOS -pxvalue flag; ?pxDirection=1 starts in REM → PX, ?pxBase=<1-48> sets the base
const query = new URLSearchParams(window.location.search);
const startValue = query.get('pxValue') ?? '16';
const startRemToPixel = query.get('pxDirection') === '1';
const startBase = clamp(
	parseInteger(query.get('pxBase') ?? '') ?? baseRange.start,
	baseRange.min,
	baseRange.max,
);

const directions = ['PX → REM', 'REM → PX'];
const typingDelayMs = 400;

const CopyIcon = <template><Icon @svg={{copySvg}} /></template>;

interface ReferenceRowSignature {
	Args: { px: number; rem: string; current: boolean; onPick: () => void };
}

const ReferenceRow: TOC<ReferenceRowSignature> = <template>
	<button
		type="button"
		class="px-to-rem-row"
		aria-label="{{@px}}px, {{@rem}}rem"
		aria-current={{if @current "true"}}
		{{press}}
		{{on "click" @onPick}}
	>
		<span>{{@px}}px</span>
		<span class="px-to-rem-row-rem">{{@rem}}</span>
	</button>
</template>;

/** The port of PxToRemViewController. */
export default class PxToRem extends Component {
	@service('canon-toast') declare toast: CanonToastService;

	@tracked text = startValue;
	/** The text the picture, the table and Copy follow: the typed text after the debounce. */
	@tracked settled = startValue;
	@tracked remToPixel = startRemToPixel;
	@tracked base: number = startBase;
	#timer?: number;

	constructor(owner: Owner, args: object) {
		super(owner, args);
		registerDestructor(this, () =>
			window.clearTimeout(this.#timer),
		);
	}

	get inputUnit() {
		return this.remToPixel ? 'rem' : 'px';
	}

	get outputUnit() {
		return this.remToPixel ? 'px' : 'rem';
	}

	resultOf(text: string) {
		return convert(
			parse(text, this.inputUnit),
			this.base,
			this.remToPixel,
		);
	}

	get result() {
		return this.resultOf(this.settled);
	}

	get pixels() {
		const typed = parse(this.settled, this.inputUnit);
		if (typed === undefined) return undefined;
		return this.remToPixel ? typed * this.base : typed;
	}

	get figure() {
		const { result } = this;
		return result === undefined
			? { text: '—', unit: '' }
			: { text: format(result), unit: this.outputUnit };
	}

	get copyDisabled() {
		return this.result === undefined;
	}

	get rows() {
		return commonPx.map((px) => ({
			px,
			rem: format(px / this.base),
			current: px === this.pixels,
		}));
	}

	#show(text: string) {
		window.clearTimeout(this.#timer);
		this.text = text;
		this.settled = text;
	}

	refresh = () => this.#show(this.text);

	typed = (text: string) => {
		this.text = text;
		window.clearTimeout(this.#timer);
		this.#timer = window.setTimeout(this.refresh, typingDelayMs);
	};

	nudge = (direction: -1 | 1) =>
		this.#show(
			nudged(
				parse(this.text, this.inputUnit),
				direction,
				this.remToPixel,
			),
		);

	// the result becomes the input, so the pair on screen stays
	pickDirection = (index: number) => {
		const result = this.resultOf(this.text);
		this.remToPixel = index === 1;
		this.#show(result === undefined ? this.text : format(result));
	};

	pickBase = (base: number) => {
		this.base = base;
		this.refresh();
	};

	use = (px: number) =>
		this.#show(format(this.remToPixel ? px / this.base : px));

	copy = () => {
		const result = this.resultOf(this.text);
		if (result === undefined) return;
		this.toast
			.write(`${format(result)}${this.outputUnit}`)
			.catch(() => {});
	};

	<template>
		<CanonSplit class="px-to-rem">
			<:banner>
				<CanonCanvas @height={{200}}>
					<Specimen
						@pixels={{this.pixels}}
						@base={{this.base}}
						@result={{this.figure.text}}
						@unit={{this.figure.unit}}
					/>
				</CanonCanvas>
			</:banner>
			<:sidebar>
				<CanonRows @framed={{true}}>
					<CanonSegmented
						@items={{directions}}
						@selected={{if
							this.remToPixel
							1
							0
						}}
						@onChange={{this.pickDirection}}
					/>
					<CanonBigNumberField
						@value={{this.text}}
						@placeholder="0"
						@unit={{upper this.inputUnit}}
						@label="Value"
						@onStep={{this.nudge}}
						@onInput={{this.typed}}
						@onEndEditing={{this.refresh}}
					/>
					<CanonRow
						@title="Base"
						@form="flush"
						as |titleId|
					>
						<CanonNumberField
							@value={{this.base}}
							@min={{baseRange.min}}
							@max={{baseRange.max}}
							@unit="px"
							@labelledBy={{titleId}}
							@onChange={{this.pickBase}}
						/>
					</CanonRow>
					<CanonButton
						@text="Copy"
						@icon={{CopyIcon}}
						@disabled={{this.copyDisabled}}
						@flashesCopied={{true}}
						@onClick={{this.copy}}
					/>
				</CanonRows>
			</:sidebar>
			<:main>
				<CanonRows @framed={{true}}>
					<CanonHeading @text="Quick Reference" />
					<div
						class="px-to-rem-row px-to-rem-row--header"
						aria-hidden="true"
					>
						<span>Pixels</span>
						<span
							class="px-to-rem-row-rem"
						>REM</span>
					</div>
					{{#each this.rows key="px" as |row|}}
						<ReferenceRow
							@px={{row.px}}
							@rem={{row.rem}}
							@current={{row.current}}
							@onPick={{fn
								this.use
								row.px
							}}
						/>
					{{/each}}
				</CanonRows>
			</:main>
		</CanonSplit>
	</template>
}

function upper(text: string) {
	return text.toUpperCase();
}
