import Component from '@glimmer/component';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import { hex, takesBlackInk, type Rgb } from '../lib/colour.ts';
import press from '../modifiers/canon-press.ts';
import type CanonToastService from '../services/canon-toast.ts';
import '../styles/tokens.css';
import './canon-swatch.css';

export interface CanonSwatchSignature {
  Args: {
    colour: Rgb;
    /** Nearest colour name for a hex, read by assistive technology. */
    nameOf?: (hex: string) => string;
  };
  Element: HTMLButtonElement;
}

/**
 * One colour, its hex where it fits; a tap copies the hex. The swatch of a
 * CanonColourStrip palette. Its width comes from the parent (a grid cell or
 * a flex item that grows): it measures itself for the hex.
 */
export default class CanonSwatch extends Component<CanonSwatchSignature> {
  @service('canon-toast') declare toast: CanonToastService;

  get hex() {
    return hex(this.args.colour);
  }

  get label() {
    const name = this.args.nameOf?.(this.hex);
    return name ? `${name} ${this.hex}` : this.hex;
  }

  get style() {
    const ink = takesBlackInk(this.args.colour) ? 'black' : 'white';
    return htmlSafe(`background: ${this.hex}; color: ${ink}`);
  }

  copy = () => void this.toast.copy(this.hex);

  <template>
    <button
      type="button"
      class="canon-swatch"
      style={{this.style}}
      aria-label={{this.label}}
      {{press}}
      {{on "click" this.copy}}
      ...attributes
    ><span
        class="canon-swatch-hex"
        aria-hidden="true"
      >{{this.hex}}</span></button>
  </template>
}
