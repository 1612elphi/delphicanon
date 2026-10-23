import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';
import { hasDigits, hundredths, timecodeRuns } from '../lib/timecode.ts';
import '../styles/tokens.css';
import './canon-timecode.css';

export interface CanonTimecodeSignature {
	Args: {
		/** Seconds to show; none shows hyphens. Ignored when `text` is set. */
		seconds?: number | null;
		/**
		 * A timecode already formatted. One without digits, or null, shows
		 * hyphens in the shape of the last one.
		 */
		text?: string | null;
		/** Replaces minutes, seconds and hundredths, for SMPTE timecode. */
		format?: (seconds: number) => string;
		/** Font size in px; default 44. */
		size?: number;
		/** CSS colour of the halo that keeps the digits clear of what runs under them; default the muted colour. */
		halo?: string;
		/** What the counter measures, for assistive technology. */
		label?: string;
	};
	Element: HTMLSpanElement;
}

/**
 * FluoWrite's full stop is 8.2 units wide against the colon's 21.8, and the
 * digits have no side bearing; padding either side seats it in a slot a
 * little wider than a colon's.
 */
export const stopPadding = ((21.8 - 8.2) / 2 + 4) / 100;

/**
 * Counter in the segment font, for the corner of a waveform band. Leading
 * zeros that carry no value are dimmed.
 */
export default class CanonTimecode extends Component<CanonTimecodeSignature> {
	#shape = hundredths(0);

	get display() {
		const { text, seconds, format } = this.args;
		const shape =
			text === undefined
				? (format ?? hundredths)(seconds ?? 0)
				: text;
		const blank =
			text === undefined
				? seconds === undefined || seconds === null
				: !hasDigits(text);
		// a null text keeps the last shape, as hyphens
		// eslint-disable-next-line ember/no-side-effects
		if (shape) this.#shape = shape;
		return { shape: this.#shape, blank };
	}

	get runs() {
		const { shape, blank } = this.display;
		return timecodeRuns(shape, blank);
	}

	get spoken() {
		const { blank } = this.display;
		return blank
			? undefined
			: this.runs.map((run) => run.text).join('');
	}

	get style() {
		const size = this.args.size ?? 44;
		const parts = [
			`--canon-timecode-size: ${size}px`,
			`--canon-timecode-stop: ${stopPadding * size}px`,
		];
		if (this.args.halo)
			parts.push(`--canon-timecode-halo: ${this.args.halo}`);
		return htmlSafe(parts.join('; '));
	}

	<template>
		<span
			class="canon-timecode"
			style={{this.style}}
			role="timer"
			aria-label={{@label}}
			...attributes
		>
			<span
				class="canon-timecode-halo"
				aria-hidden="true"
			>{{#each this.runs as |run|}}<span
						class={{if
							run.stop
							"canon-timecode-stop"
						}}
					>{{run.text}}</span>{{/each}}</span>
			<span
				class="canon-timecode-digits"
				aria-hidden="true"
			>{{#each this.runs as |run|}}<span
						class="{{if
								run.stop
								'canon-timecode-stop'
							}}
							{{if
								run.dim
								'canon-timecode-dim'
							}}"
					>{{run.text}}</span>{{/each}}</span>
			{{#if this.spoken}}
				<span
					class="canon-timecode-spoken"
				>{{this.spoken}}</span>
			{{/if}}
		</span>
	</template>
}
