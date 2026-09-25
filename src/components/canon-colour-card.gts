import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';
import {
  contrastFigure,
  contrastLevels,
  contrastRatio,
  formatColour,
  formatLabel,
  hex,
  type ColourFormat,
  type Rgb,
} from '../lib/colour.ts';
import CanonValueLine from './canon-value-line.gts';
import '../styles/tokens.css';
import './canon-colour-card.css';

export interface CanonColourCardSignature {
  Args: {
    colour: Rgb;
    /**
     * chip: swatch above, name and three values below. row: swatch at the
     * leading edge, name and one value beside it, for lists.
     */
    layout?: 'chip' | 'row';
    /** Shown instead of the nearest named colour. */
    name?: string;
    /** Nearest colour name for a hex. */
    nameOf?: (hex: string) => string;
    /** The app's colour format settings; default hex and rgb. */
    primaryFormat?: ColourFormat;
    secondaryFormat?: ColourFormat;
  };
  Element: HTMLDivElement;
}

/**
 * A paint chip: the colour over its name and values. The swatch carries
 * white and black type with their contrast ratios; each value line copies
 * itself on a tap.
 */
export default class CanonColourCard extends Component<CanonColourCardSignature> {
  get layout() {
    return this.args.layout ?? 'chip';
  }

  get hex() {
    return hex(this.args.colour);
  }

  get name() {
    return this.args.name ?? this.args.nameOf?.(this.hex) ?? this.hex;
  }

  get swatchStyle() {
    return htmlSafe(`background: ${this.hex}`);
  }

  get lines() {
    const shown: ColourFormat[] = ['hex'];
    for (const format of [
      this.args.primaryFormat ?? 'hex',
      this.args.secondaryFormat ?? 'rgb',
      'oklch',
      'rgb',
    ] as const) {
      if (!shown.includes(format)) shown.push(format);
    }
    return shown.slice(0, this.layout === 'chip' ? 3 : 1).map((format) => ({
      label: formatLabel(format),
      value: formatColour(this.args.colour, format),
    }));
  }

  get inks() {
    return [1, 0].map((level) => {
      const ratio = contrastRatio(this.args.colour, [level, level, level]);
      const faint = ratio < contrastLevels.aa;
      return {
        figure: contrastFigure(ratio),
        style: htmlSafe(
          `color: ${level ? 'white' : 'black'}; opacity: ${faint ? 0.45 : 1}`,
        ),
      };
    });
  }

  <template>
    <div
      class="canon-colour-card canon-colour-card--{{this.layout}}"
      ...attributes
    >
      <div class="canon-colour-card-swatch" style={{this.swatchStyle}}>
        {{#if (eq this.layout "chip")}}
          {{#each this.inks as |ink|}}
            <span
              class="canon-colour-card-ink"
              style={{ink.style}}
              aria-hidden="true"
            >
              <span class="canon-colour-card-specimen">Aa</span>
              <span class="canon-colour-card-ratio">{{ink.figure}}</span>
            </span>
          {{/each}}
        {{/if}}
      </div>
      <div class="canon-colour-card-info">
        <div class="canon-colour-card-name">{{this.name}}</div>
        {{#each this.lines as |line|}}
          <CanonValueLine @label={{line.label}} @value={{line.value}} />
        {{/each}}
      </div>
    </div>
  </template>
}

function eq(a: unknown, b: unknown) {
  return a === b;
}
