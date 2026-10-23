import type { TOC } from '@ember/component/template-only';
import { htmlSafe } from '@ember/template';
import CanonFigure from '#src/components/canon-figure.gts';
import CanonIcon from '#src/components/canon-icon.gts';
import { contrastFigure, hex, type Rgb } from '#src/lib/colour.ts';
import bell from 'lucide-static/icons/bell.svg?raw';
import circleDot from 'lucide-static/icons/circle-dot.svg?raw';
import search from 'lucide-static/icons/search.svg?raw';
import squareCheck from 'lucide-static/icons/square-check.svg?raw';
import star from 'lucide-static/icons/star.svg?raw';
import toggle from 'lucide-static/icons/toggle-right.svg?raw';

/** Band height in px, as ContrastSpecimen.height. */
export const specimenHeight = 276;

// wcag 2.2 large text: 18 pt, or 14 pt bold, at 4/3 px per pt
const lines = [
	{ text: 'Large', size: 'large', note: '18 pt' },
	{ text: 'Bold', size: 'bold', note: '14 pt' },
	{ text: 'Normal', size: 'normal', note: '12 pt' },
	{ text: 'Aa Bb Cc Dd Ee Ff Gg 0123456789', size: 'normal', note: '' },
];

const symbols = [squareCheck, circleDot, toggle, star, search, bell];

function style(foreground: Rgb, background: Rgb) {
	return htmlSafe(
		`--contrast-ink: ${hex(foreground)}; --contrast-ground: ${hex(background)}`,
	);
}

interface SpecimenSignature {
	Args: {
		foreground: Rgb;
		background: Rgb;
		ratio: number;
		animated: boolean;
	};
}

/** The foreground on the background: the ratio as a figure, type at the sizes WCAG names and a row of controls. */
const Specimen: TOC<SpecimenSignature> = <template>
	<div
		class="contrast-specimen"
		role="group"
		aria-label="Preview"
		style={{style @foreground @background}}
	>
		<div class="contrast-specimen-columns">
			<CanonFigure
				class="contrast-specimen-figure"
				@text={{contrastFigure @ratio}}
				@unit=":1"
				@size={{56}}
				@colour={{hex @foreground}}
				@animated={{@animated}}
			/>
			<div class="contrast-specimen-type">
				{{#each lines as |line|}}
					<div class="contrast-specimen-line">
						<span
							class="contrast-specimen-text contrast-specimen--{{line.size}}"
						>{{line.text}}</span>
						<span
							class="contrast-specimen-note"
						>{{line.note}}</span>
					</div>
				{{/each}}
				<div
					class="contrast-specimen-line contrast-specimen-controls"
				>
					<span
						class="contrast-specimen-symbols"
						aria-hidden="true"
					>
						{{#each symbols as |svg|}}
							<span
								class="contrast-specimen-symbol"
							><CanonIcon
									@svg={{svg}}
								/></span>
						{{/each}}
					</span>
					<span
						class="contrast-specimen-note"
					>Controls</span>
				</div>
			</div>
		</div>
	</div>
</template>;

export default Specimen;
