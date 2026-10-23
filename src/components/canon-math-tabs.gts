import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import press from '../modifiers/canon-press.ts';
import CanonMathView from './canon-math-view.gts';
import { canvasMetrics } from '../lib/math/measure.ts';
import { Typesetter } from '../lib/math/typeset.ts';
import '../styles/tokens.css';
import './canon-math-tabs.css';

export interface CanonMathTabsSignature {
	Args: {
		/** The page position, fractional mid-swipe. */
		progress: number;
		onSelect?: (page: number) => void;
	};
	Element: HTMLDivElement;
}

const accents = [
	'var(--canon-foreground)',
	'var(--canon-math-green)',
	'var(--canon-math-blue)',
	'var(--canon-math-clay)',
];
const names = ['Numbers', 'Functions', 'Calculus', 'Letters'];
export const lampHeight = 3;

function faces() {
	const setter = new Typesetter(canvasMetrics, 18);
	const functions = setter
		.text('f', { italic: true })
		.append(
			setter.parens(setter.text('x', { italic: true }), 0),
			1,
		);
	const calculus = setter.text('∫').append(setter.text('Σ'), 3);
	return [
		setter.text('123'),
		functions,
		calculus,
		setter.text('xyz', { italic: true }),
	];
}

/**
 * The pages' names as maths, each lit in its page's colour as the page comes
 * into view, over a lamp that slides and changes colour with the swipe.
 */
export default class CanonMathTabs extends Component<CanonMathTabsSignature> {
	faces = faces();

	get progress() {
		return Math.min(
			Math.max(this.args.progress, 0),
			names.length - 1,
		);
	}

	get tabs() {
		return this.faces.map((face, index) => {
			const near = Math.max(
				0,
				1 - Math.abs(this.progress - index),
			);
			return {
				face,
				index,
				name: names[index]!,
				selected: near > 0.5,
				style: htmlSafe(
					`color: color-mix(in srgb, var(--canon-muted-foreground), ${accents[index]} ${Math.round(near * 100)}%)`,
				),
			};
		});
	}

	get lampStyle() {
		const low = Math.floor(this.progress);
		const high = Math.min(low + 1, names.length - 1);
		const share = this.progress - low;
		// lamp narrows mid-swipe
		const width = 0.62 * (1 - 0.35 * Math.sin(Math.PI * share));
		return htmlSafe(
			`--canon-math-progress: ${this.progress}; --canon-math-lamp: ${width}; background: color-mix(in srgb, ${accents[low]}, ${accents[high]} ${Math.round(share * 100)}%)`,
		);
	}

	select = (index: number) => this.args.onSelect?.(index);

	<template>
		<div class="canon-math-tabs" ...attributes>
			{{#each this.tabs as |tab|}}
				<button
					type="button"
					class="canon-math-tab"
					aria-label={{tab.name}}
					aria-current={{if tab.selected "true"}}
					style={{tab.style}}
					{{press}}
					{{on
						"click"
						(fn this.select tab.index)
					}}
				><CanonMathView
						@box={{tab.face}}
						@mono={{true}}
						aria-hidden="true"
					/></button>
			{{/each}}
			<span
				class="canon-math-tabs-lamp"
				style={{this.lampStyle}}
			></span>
		</div>
	</template>
}
