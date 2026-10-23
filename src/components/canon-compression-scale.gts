import type { TOC } from '@ember/component/template-only';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import CanonBar from './canon-bar.gts';
import CanonFigure from './canon-figure.gts';
import CanonLoader from './canon-loader.gts';
import { barLabel, compressionScale, labelSpare } from '../lib/compression.ts';
import { springEasing } from '../lib/motion.ts';
import '../styles/tokens.css';
import './canon-compression-scale.css';

export interface CanonCompressionScaleSignature {
	Args: {
		/** The original's size in bytes; 0 before a file. */
		before: number;
		/** The result's size in bytes; 0 before a result. */
		after: number;
		/** The result bar's label. */
		format: string;
		/** Shows the loader beside the figure. */
		working?: boolean;
	};
	Element: HTMLDivElement;
}

// the iOS bar spring: 0.6 s, damping 0.7
const springStyle = htmlSafe(
	`--canon-compression-scale-easing: ${springEasing(0.7)}`,
);

/** The label sits inside the fill when it fits with 20 px to spare, else after it. */
const place = modifier((bar: HTMLElement, [share]: [number, string]) => {
	const label = bar.querySelector<HTMLElement>(
		'.canon-compression-scale-label',
	)!;
	const update = () =>
		bar.toggleAttribute(
			'data-inside',
			bar.clientWidth * share >=
				label.offsetWidth + labelSpare,
		);
	update();
	const observer = new ResizeObserver(update);
	observer.observe(bar);
	return () => observer.disconnect();
});

const barStyle = (share: number, ink: string) =>
	htmlSafe(
		`--canon-compression-scale-share: ${Math.min(Math.max(share, 0), 1)}; --canon-compression-scale-ink: ${ink}`,
	);

interface BarSignature {
	Args: {
		label: string;
		bytes: number;
		share: number;
		fill: string;
		/** Label colour inside the fill. */
		ink: string;
	};
}

const Bar: TOC<BarSignature> = <template>
	<div
		class="canon-compression-scale-bar"
		style={{barStyle @share @ink}}
		{{place @share (barLabel @label @bytes)}}
	>
		<CanonBar
			@share={{@share}}
			@fill={{@fill}}
			@track="transparent"
		/>
		<span class="canon-compression-scale-label">{{barLabel
				@label
				@bytes
			}}</span>
	</div>
</template>;

const colour = (grew: boolean) =>
	grew ? 'var(--canon-destructive)' : 'var(--canon-primary)';

/** Two bars to one scale, the original's bytes over the result's, with the saving as a figure. */
const CanonCompressionScale: TOC<CanonCompressionScaleSignature> = <template>
	{{#let (compressionScale @before @after) as |scale|}}
		<div
			class="canon-compression-scale"
			style={{springStyle}}
			...attributes
		>
			<div class="canon-compression-scale-top">
				{{#if @working}}
					<CanonLoader
						class="canon-compression-scale-loader"
						@cell={{5}}
						@gap={{1}}
					/>
				{{/if}}
				<CanonFigure
					@text={{scale.figure}}
					@unit={{scale.unit}}
					@colour={{colour scale.grew}}
				/>
			</div>
			<Bar
				@label="Original"
				@bytes={{@before}}
				@share={{1}}
				@fill="var(--canon-muted)"
				@ink="var(--canon-foreground)"
			/>
			<Bar
				@label={{@format}}
				@bytes={{if scale.known @after 0}}
				@share={{scale.share}}
				@fill={{colour scale.grew}}
				@ink="var(--canon-primary-foreground)"
			/>
		</div>
	{{/let}}
</template>;

export default CanonCompressionScale;
