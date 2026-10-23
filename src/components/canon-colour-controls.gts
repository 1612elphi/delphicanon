import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { modifier } from 'ember-modifier';
import type { Rgb } from '../lib/colour.ts';
import {
	channels,
	colourAt,
	pointFor,
	solidSpaces,
	spaceNames,
	type SolidPoint,
	type SolidSpace,
} from '../lib/colour-space.ts';
import CanonColourNotationInput from './canon-colour-notation-input.gts';
import CanonRow from './canon-row.gts';
import CanonSegmented from './canon-segmented.gts';
import CanonSlider from './canon-slider.gts';
import CanonSwitch from './canon-switch.gts';
import '../styles/tokens.css';
import './canon-colour-controls.css';

/**
 * What a CanonColourSolid shows and what its controls change: the Swift
 * controls held the solid itself, so here both read one state. Pass
 * `space`, `point`, `animated`, `sliceAxis`, `isOrtho` and `showsWhole` to
 * the solid and `pick` as its `onChange`. A new space reaches the solid with
 * the old point; the solid converts it and reports it through `pick`.
 */
export class CanonColourSolidState {
	@tracked space: SolidSpace;
	@tracked point: SolidPoint;
	/** The last change of `point` eases, as after a tap on a slider track; drags and picks follow at once. */
	@tracked animated = false;
	/** The slider row that is the solid's slice; row 3, CMYK's black, never slices. */
	@tracked activeRow: number;
	/** Slices along the active row's channel; false cuts the solid away instead. */
	@tracked slices = true;
	/** The View plane switch. */
	@tracked viewPlane = false;
	/** True while CMYK's black changes. */
	@tracked showsWhole = false;

	constructor({
		space = 'hsl',
		colour = [0.12, 0.4, 0.15],
		activeRow = 0,
	}: { space?: SolidSpace; colour?: Rgb; activeRow?: number } = {}) {
		this.space = space;
		this.point = pointFor(space, colour);
		this.activeRow = activeRow;
	}

	get colour(): Rgb {
		return colourAt(this.space, this.point);
	}

	get isOrtho(): boolean {
		return this.slices && this.viewPlane;
	}

	get sliceAxis(): number | undefined {
		if (!this.slices) return undefined;
		return channels(this.space)[Math.min(this.activeRow, 2)]?.axis;
	}

	setPoint(point: SolidPoint, animated: boolean) {
		this.animated = animated;
		this.point = point;
	}

	/** Eases to `colour`. */
	use = (colour: Rgb) => {
		this.setPoint(pointFor(this.space, colour), true);
	};

	selectSpace(space: SolidSpace) {
		this.space = space;
	}

	/** The solid's change callback. */
	pick = (point: SolidPoint) => this.setPoint(point, false);
}

export interface CanonColourControlsSignature {
	Args: {
		state: CanonColourSolidState;
		/** Title of the notation row; default Any notation. */
		notationTitle?: string;
		/** Leaves out the notation row, for a tool with its own input. */
		hidesNotation?: boolean;
	};
	/** Rows placed between the sliders and the View plane switch. */
	Blocks: { default: [] };
	Element: HTMLDivElement;
}

const spaceTitles = solidSpaces.map((space) => spaceNames[space]);
const fixed = (decimals: number) => (value: number) => value.toFixed(decimals);

/**
 * Rows that drive a CanonColourSolid: any notation beside an eyedropper,
 * the space, one slider per channel and the View plane switch. The active
 * slider row is the solid's slice. Place it inside a CanonRows.
 */
export default class CanonColourControls extends Component<CanonColourControlsSignature> {
	get state() {
		return this.args.state;
	}

	get spaceIndex() {
		return solidSpaces.indexOf(this.state.space);
	}

	get rows() {
		const { state } = this;
		const list = channels(state.space);
		const lit = state.slices ? Math.min(state.activeRow, 2) : -1;
		const longest = list.reduce(
			(a, c) => (c.name.length > a.length ? c.name : a),
			'',
		);
		return list.map((channel, index) => ({
			index,
			channel,
			value:
				state.point[channel.axis]! * channel.scale +
				channel.offset,
			lit: index === lit,
			longest,
		}));
	}

	selectSpace = (index: number) => {
		this.state.selectSpace(solidSpaces[index]!);
	};

	slide = (index: number, value: number, dragging: boolean) => {
		const channel = channels(this.state.space)[index];
		if (!channel) return;
		if (index < 3) this.state.activeRow = index;
		const next = [...this.state.point] as SolidPoint;
		next[channel.axis] = (value - channel.offset) / channel.scale;
		// taps ease, drags follow
		this.state.setPoint(next, !dragging);
	};

	// CanonSlider has no touch-down callback: a touch picks the row, black shows the whole solid
	touch = modifier((slider: HTMLElement, [index]: [number]) => {
		const down = () => {
			if (index === 3) this.state.showsWhole = true;
			else this.state.activeRow = index;
			window.addEventListener('pointerup', up);
			window.addEventListener('pointercancel', up);
		};
		const up = () => {
			this.state.showsWhole = false;
			window.removeEventListener('pointerup', up);
			window.removeEventListener('pointercancel', up);
		};
		slider.addEventListener('pointerdown', down);
		return () => {
			slider.removeEventListener('pointerdown', down);
			up();
		};
	});

	toggleViewPlane = (on: boolean) => {
		this.state.viewPlane = on;
	};

	<template>
		<div class="canon-colour-controls" ...attributes>
			{{#unless @hidesNotation}}
				<CanonRow
					@title={{if
						@notationTitle
						@notationTitle
						"Any notation"
					}}
					@form="stacked"
					as |titleId|
				>
					<CanonColourNotationInput
						@colour={{this.state.colour}}
						@onColour={{this.state.use}}
						@labelledBy={{titleId}}
					/>
				</CanonRow>
			{{/unless}}
			<CanonRow @title="Space" @form="stacked">
				<CanonSegmented
					@items={{spaceTitles}}
					@selected={{this.spaceIndex}}
					@columns={{4}}
					@onChange={{this.selectSpace}}
				/>
			</CanonRow>
			{{#each this.rows key="index" as |row|}}
				<CanonRow
					class="canon-colour-controls-channel
						{{if
							row.lit
							'canon-colour-controls-lit'
						}}"
					@title={{row.channel.name}}
					@detail={{row.channel.detail}}
					@form="flush"
					@sizingTitle={{row.longest}}
					as |titleId|
				>
					<CanonSlider
						@value={{row.value}}
						@min={{row.channel.min}}
						@max={{row.channel.max}}
						@readout={{fixed
							row.channel.decimals
						}}
						@labelledBy={{titleId}}
						@onChange={{fn
							this.slide
							row.index
						}}
						{{this.touch row.index}}
					/>
				</CanonRow>
			{{/each}}
			{{yield}}
			<CanonRow @title="View plane" as |titleId|>
				<CanonSwitch
					@on={{this.state.viewPlane}}
					@onChange={{this.toggleViewPlane}}
					aria-labelledby={{titleId}}
				/>
			</CanonRow>
		</div>
	</template>
}
