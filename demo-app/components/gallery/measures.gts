import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonCompressionScale from '#src/components/canon-compression-scale.gts';
import CanonDimensionLine from '#src/components/canon-dimension-line.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonSegmented from '#src/components/canon-segmented.gts';
import CanonSwitch from '#src/components/canon-switch.gts';
import { dimensionLines, sheet, type Rect } from '#src/lib/dimension-line.ts';
import './measures.css';

export const pane = 'main';
export const order = 16;

const picture = { width: 1600, height: 1200 };

const scales = [
	{ title: 'Saved', before: 2_400_000, after: 1_700_000, working: false },
	{ title: 'Grew', before: 2_400_000, after: 3_100_000, working: false },
	{ title: 'Even', before: 2_400_000, after: 2_400_000, working: false },
	{ title: 'Working', before: 2_400_000, after: 0, working: true },
	{ title: 'Empty', before: 0, after: 0, working: false },
];
const titles = scales.map((scale) => scale.title);

const box = ({ x, y, width, height }: Rect) =>
	htmlSafe(
		`inset-inline-start: ${x}px; inset-block-start: ${y}px; inline-size: ${width}px; block-size: ${height}px`,
	);

export default class Measures extends Component {
	@tracked area: Rect = { x: 0, y: 0, width: 0, height: 0 };
	@tracked scale = 0;
	@tracked blank = false;

	get frame() {
		return sheet(picture, this.area);
	}

	get lines() {
		const { across, down } = dimensionLines(this.frame);
		return {
			sheet: box(this.frame),
			across: box(across),
			down: box(down),
		};
	}

	get shown() {
		return scales[this.scale]!;
	}

	measure = modifier((element: HTMLElement) => {
		const observer = new ResizeObserver(() => {
			this.area = {
				x: element.offsetLeft,
				y: element.offsetTop,
				width: element.clientWidth,
				height: element.clientHeight,
			};
		});
		observer.observe(element);
		return () => observer.disconnect();
	});

	pick = (index: number) => {
		this.scale = index;
	};

	toggle = (on: boolean) => {
		this.blank = on;
	};

	<template>
		<CanonCanvas @height={{220}} @background="var(--canon-muted)">
			<div class="gallery-dimensions">
				<span
					class="gallery-dimensions-area"
					{{this.measure}}
				></span>
				{{#if this.area.width}}
					<span
						class="gallery-dimensions-sheet"
						style={{this.lines.sheet}}
					></span>
					<CanonDimensionLine
						@pixels={{picture.width}}
						@blank={{this.blank}}
						style={{this.lines.across}}
					/>
					<CanonDimensionLine
						@pixels={{picture.height}}
						@blank={{this.blank}}
						@down={{true}}
						style={{this.lines.down}}
					/>
				{{/if}}
			</div>
		</CanonCanvas>
		<CanonCanvas @height={{176}}>
			<CanonCompressionScale
				@before={{this.shown.before}}
				@after={{this.shown.after}}
				@format="JPEG"
				@working={{this.shown.working}}
			/>
		</CanonCanvas>
		<CanonRows @framed={{true}}>
			<CanonHeading @text="Measures" />
			<CanonSegmented
				@items={{titles}}
				@selected={{this.scale}}
				@onChange={{this.pick}}
			/>
			<CanonRow @title="Blank" as |titleId|>
				<CanonSwitch
					@on={{this.blank}}
					@onChange={{this.toggle}}
					aria-labelledby={{titleId}}
				/>
			</CanonRow>
		</CanonRows>
	</template>
}
