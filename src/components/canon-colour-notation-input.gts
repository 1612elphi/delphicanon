import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import CanonButton from './canon-button.gts';
import CanonRule from './canon-rule.gts';
import CanonTextCell from './canon-text-cell.gts';
import { hex, parseColour, parseHex, type Rgb } from '../lib/colour.ts';
import { Pipette } from '../lib/control-icons.gts';
import '../styles/tokens.css';
import './canon-colour-notation-input.css';

export interface CanonColourNotationInputSignature {
  Args: {
    /** Shown as hex while the field is not being typed in. */
    colour?: Rgb;
    /** A formatted value shown instead of `colour`'s hex. */
    text?: string;
    /** A picked colour, and a typed one read by the default `parse`. */
    onColour?: (colour: Rgb) => void;
    /**
     * Reads typed text and uses it; false turns the text red. The default
     * reads any notation `parseColour` knows and passes it to `onColour`.
     */
    parse?: (text: string) => boolean;
    placeholder?: string;
    /** Id of the element that names the field, such as a row title. */
    labelledBy?: string;
    label?: string;
  };
  Element: HTMLDivElement;
}

/** Typed text is read after this pause, on Return, and when the field loses focus. */
export const typingPauseMs = 400;

interface EyeDropperResult {
  sRGBHex: string;
}

type EyeDropperWindow = Window & {
  EyeDropper?: new () => { open(): Promise<EyeDropperResult> };
};

/**
 * A colour typed in any notation beside an eyedropper cell. The eyedropper
 * is the browser's EyeDropper and is left out where the browser has none.
 */
export default class CanonColourNotationInput extends Component<CanonColourNotationInputSignature> {
  // the typed text holds until what is shown changes
  @tracked typed?: { text: string; over: string };
  @tracked fails = false;
  #typing?: number;
  #focused = false;
  readonly hasEyedropper = 'EyeDropper' in window;

  get shown() {
    return this.args.text ?? (this.args.colour ? hex(this.args.colour) : '');
  }

  get value() {
    const { typed } = this;
    return typed && (this.#focused || typed.over === this.shown)
      ? typed.text
      : this.shown;
  }

  get failing() {
    return this.fails && this.value === this.typed?.text;
  }

  parse = (text: string): boolean => {
    if (this.args.parse) return this.args.parse(text);
    const colour = parseColour(text);
    if (colour) this.args.onColour?.(colour);
    return colour !== undefined;
  };

  read = () => {
    window.clearTimeout(this.#typing);
    const text = this.typed?.text;
    if (text === undefined) return;
    this.fails = !this.parse(text) && text.trim() !== '';
  };

  type = (text: string) => {
    this.typed = { text, over: this.shown };
    this.fails = false;
    window.clearTimeout(this.#typing);
    this.#typing = window.setTimeout(this.read, typingPauseMs);
  };

  focus = () => {
    this.#focused = true;
  };

  leave = () => {
    this.#focused = false;
    this.read();
    if (this.typed) this.typed = { ...this.typed, over: this.shown };
  };

  pick = async () => {
    const { EyeDropper } = window as EyeDropperWindow;
    if (!EyeDropper) return;
    try {
      const { sRGBHex } = await new EyeDropper().open();
      const colour = parseHex(sRGBHex);
      if (colour) this.args.onColour?.(colour);
    } catch {
      // Escape closes the eyedropper with an AbortError
    }
  };

  willDestroy() {
    super.willDestroy();
    window.clearTimeout(this.#typing);
  }

  <template>
    <div class="canon-colour-notation-input" ...attributes>
      <CanonTextCell
        class="canon-colour-notation-input-field
          {{if this.failing 'canon-colour-notation-input--fails'}}"
        @value={{this.value}}
        @placeholder={{if @placeholder @placeholder "oklch(0.64 0.15 264)"}}
        @onChange={{this.type}}
        spellcheck="false"
        autocomplete="off"
        autocapitalize="off"
        aria-labelledby={{@labelledBy}}
        aria-label={{@label}}
        aria-invalid={{if this.failing "true"}}
        {{on "focus" this.focus}}
        {{on "blur" this.leave}}
      />
      {{#if this.hasEyedropper}}
        <CanonRule @vertical={{true}} />
        <CanonButton
          @kind="cell"
          @icon={{Pipette}}
          @label="Colour"
          @onClick={{this.pick}}
        />
      {{/if}}
    </div>
  </template>
}
