import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonImageCompare from '#src/components/canon-image-compare.gts';
import CanonPageStrip, {
	pageStripHeight,
	type CanonPage,
} from '#src/components/canon-page-strip.gts';

export const pane = 'main';
export const order = 15;

function hsv(h: number, s: number, v: number) {
	const f = (n: number) => {
		const k = (n + h * 6) % 6;
		return Math.round(
			255 * (v - v * s * Math.max(0, Math.min(k, 4 - k, 1))),
		);
	};
	return `rgb(${f(5)},${f(3)},${f(1)})`;
}

function bands(saturation: number) {
	const rects = Array.from(
		{ length: 32 },
		(_, x) =>
			`<rect x="${x * 10}" width="10" height="160" shape-rendering="crispEdges" fill="${hsv(x / 32, saturation, 0.9)}"/>`,
	).join('');
	return `data:image/svg+xml,${encodeURIComponent(
		`<svg xmlns="http://www.w3.org/2000/svg" width="320" height="160">${rects}</svg>`,
	)}`;
}

const before = bands(0.8);
const after = bands(0);

export default class Pages extends Component {
	@tracked pages: CanonPage[] = [
		{ size: { width: 595, height: 842 }, name: 'Plain' },
		{ size: { width: 842, height: 595 }, name: 'Lit' },
		{
			size: { width: 595, height: 842 },
			name: 'Depth 2',
			depth: 2,
		},
		{
			size: { width: 595, height: 842 },
			name: 'Picture',
			picture: before,
			area: { x: 40, y: 60, width: 515, height: 722 },
			placement: { x: 40, y: 262, width: 515, height: 320 },
			turn: 90,
		},
	];
	@tracked selected = 1;

	select = (index: number) => {
		this.selected = index;
	};

	move = (from: number, to: number) => {
		const pages = [...this.pages];
		pages.splice(to, 0, ...pages.splice(from, 1));
		if (this.selected === from) this.selected = to;
		this.pages = pages;
	};

	menu = (index: number) => [
		{ title: 'Duplicate', action: () => this.duplicate(index) },
		{
			title: 'Delete',
			action: () => this.remove(index),
			destructive: true,
		},
	];

	duplicate(index: number) {
		const pages = [...this.pages];
		pages.splice(index + 1, 0, pages[index]!);
		this.pages = pages;
	}

	remove(index: number) {
		this.pages = this.pages.filter((_, i) => i !== index);
	}

	<template>
		<CanonCanvas
			@height={{pageStripHeight}}
			@background="var(--canon-muted)"
		>
			<CanonPageStrip
				@pages={{this.pages}}
				@selected={{this.selected}}
				@onSelect={{this.select}}
				@reorders={{true}}
				@onMove={{this.move}}
				@menu={{this.menu}}
			/>
		</CanonCanvas>
		<CanonCanvas @aspect={{2}} @background="var(--canon-muted)">
			<CanonImageCompare
				@before={{before}}
				@after={{after}}
				@afterTitle="Grey"
			/>
		</CanonCanvas>
	</template>
}
