import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { service } from '@ember/service';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import {
  formatColour,
  hex,
  takesBlackInk,
  type ColourFormat,
  type Rgb,
} from '../lib/colour.ts';
import { springEasing } from '../lib/motion.ts';
import type CanonToastService from '../services/canon-toast.ts';
import CanonGrid from './canon-grid.gts';
import CanonHeading from './canon-heading.gts';
import '../styles/tokens.css';
import './canon-palette-card.css';

export interface CanonPaletteCardSignature {
  Args: {
    title: string;
    colours: Rgb[];
    /** Height of the swatches in px. */
    height?: number;
    selected?: number;
    onSelect?: (index: number | undefined) => void;
    /** Nearest colour name for a hex, shown on the widened swatch. */
    nameOf?: (hex: string) => string;
    /** The app's colour format settings; the widened swatch shows the first that is not hex. */
    primaryFormat?: ColourFormat;
    secondaryFormat?: ColourFormat;
  };
  Blocks: {
    /** A choice between palettes, under the heading: a CanonSegmented. */
    picker: [];
    /** Flush cells in a bar under the swatches: CanonButtons of kind cell. */
    actions: [];
  };
  Element: HTMLDivElement;
}

/** Width of the widened swatch against the others. */
export const widened = 3;
const spring = springEasing(0.82);

/**
 * A palette as swatches meeting at hairlines, under a heading. A tap widens
 * a swatch to show its name and values; a tap on the widened swatch copies
 * its hex.
 */
export default class CanonPaletteCard extends Component<CanonPaletteCardSignature> {
  @service('canon-toast') declare toast: CanonToastService;
  // a pick holds until the selected arg changes
  @tracked picked?: { index: number; over: number | undefined };

  get selected(): number | undefined {
    const { picked } = this;
    const index =
      picked && picked.over === this.args.selected
        ? picked.index
        : this.args.selected;
    return index !== undefined && index < this.args.colours.length
      ? index
      : undefined;
  }

  get stripStyle() {
    return htmlSafe(
      `block-size: ${this.args.height ?? 156}px; --canon-palette-spring: ${spring}`,
    );
  }

  get detailFormat(): ColourFormat {
    return (
      [
        this.args.primaryFormat ?? 'hex',
        this.args.secondaryFormat ?? 'rgb',
      ].find((format) => format !== 'hex') ?? 'oklch'
    );
  }

  get swatches() {
    return this.args.colours.map((colour, index) => {
      const code = hex(colour);
      const wide = index === this.selected;
      const name = wide ? this.args.nameOf?.(code) : undefined;
      return {
        index,
        hex: code,
        wide,
        name,
        label: this.args.nameOf?.(code) ?? code,
        details: formatColour(colour, this.detailFormat),
        style: htmlSafe(
          `background: ${code}; color: ${takesBlackInk(colour) ? 'black' : 'white'}; flex-grow: ${wide ? widened : 1}`,
        ),
      };
    });
  }

  tap = (index: number) => {
    if (index === this.selected) {
      void this.toast.copy(hex(this.args.colours[index]!));
      return;
    }
    this.picked = { index, over: this.args.selected };
    this.args.onSelect?.(index);
  };

  <template>
    <div class="canon-palette-card" ...attributes>
      <CanonHeading @text={{@title}} />
      {{yield to="picker"}}
      <div class="canon-palette-card-strip" style={{this.stripStyle}}>
        {{#each this.swatches key="@index" as |swatch|}}
          <button
            type="button"
            class="canon-palette-card-swatch
              {{if swatch.wide 'canon-palette-card-swatch--wide'}}"
            style={{swatch.style}}
            aria-label={{swatch.label}}
            aria-pressed={{if swatch.wide "true" "false"}}
            {{on "click" (fn this.tap swatch.index)}}
          >
            <span class="canon-palette-card-name">{{swatch.name}}</span>
            <span class="canon-palette-card-details">{{swatch.details}}</span>
            <span class="canon-palette-card-hex">{{swatch.hex}}</span>
          </button>
        {{/each}}
      </div>
      {{#if (has-block "actions")}}
        <CanonGrid>{{yield to="actions"}}</CanonGrid>
      {{/if}}
    </div>
  </template>
}
