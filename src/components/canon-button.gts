import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { modifier } from 'ember-modifier';
import type { ComponentLike } from '@glint/template';
import press from '../modifiers/canon-press.ts';
import '../styles/tokens.css';
import './canon-button.css';

export type CanonButtonKind = 'primary' | 'secondary' | 'cell' | 'segment';

export interface CanonButtonSignature {
  Args: {
    /** The title. Empty shows the icon alone. */
    text?: string;
    /** Rendered as the symbol; the consumer supplies it (lucide in the web app). */
    icon?: ComponentLike;
    /**
     * inline: small, beside the title. oversized: large and faint behind the
     * title, turned, cut off by the trailing and bottom edges. Keep it rare.
     */
    iconStyle?: 'inline' | 'oversized';
    /**
     * primary: the tool's main verb, fills its container. secondary: fills
     * its container. cell: content width, the enclosing grid or flush row
     * draws the lines. segment: a cell that shows `selected`.
     */
    kind?: CanonButtonKind;
    selected?: boolean;
    disabled?: boolean;
    /** Accessible name when the title is empty or dropped. */
    label?: string;
    onClick?: () => void;
    /** Holding the button runs onClick again and again; a tap runs it once. */
    repeats?: boolean;
    /** Shows Copied with a check for 1.5 s after each click. */
    flashesCopied?: boolean;
  };
  Element: HTMLButtonElement;
}

/** Seconds before a held button repeats, between repeats, and between repeats after ten. */
export const repeatTiming = { delay: 0.4, interval: 0.09, fast: 0.04 } as const;
export const flashSeconds = 1.5;

const Check = <template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
  ><path d="M20 6 9 17l-5-5" /></svg>
</template>;

export default class CanonButton extends Component<CanonButtonSignature> {
  @tracked flashing = false;
  #flashTimer?: number;
  #holdTimer?: number;
  #held = false;
  #didRepeat = false;

  get kind(): CanonButtonKind {
    return this.args.kind ?? 'secondary';
  }

  get text(): string {
    return this.flashing ? 'Copied' : (this.args.text ?? '');
  }

  get icon(): ComponentLike | undefined {
    return this.flashing ? Check : this.args.icon;
  }

  get oversized() {
    return this.args.iconStyle === 'oversized' && this.icon !== undefined;
  }

  get filled() {
    return (
      this.kind === 'primary' ||
      (this.args.selected === true &&
        (this.kind === 'segment' || this.kind === 'secondary'))
    );
  }

  /** A grid drops the title of a filling button with a symbol when it does not fit. */
  get fits() {
    return (
      (this.kind === 'primary' || this.kind === 'secondary') &&
      this.text !== '' &&
      this.icon !== undefined &&
      !this.oversized
    );
  }

  get label() {
    if (this.icon === undefined) return undefined;
    return this.args.label ?? (this.text || undefined);
  }

  @action click() {
    if (this.#didRepeat) {
      this.#didRepeat = false;
      return;
    }
    this.args.onClick?.();
    if (this.args.flashesCopied) this.flash();
  }

  flash() {
    this.flashing = true;
    window.clearTimeout(this.#flashTimer);
    this.#flashTimer = window.setTimeout(() => {
      this.flashing = false;
    }, flashSeconds * 1000);
  }

  // template-lint forbids binding pointerdown; a hold starts there
  repeat = modifier((button: HTMLButtonElement) => {
    const hold = (event: PointerEvent) => {
      if (!this.args.repeats || event.button !== 0) return;
      this.#held = true;
      this.#didRepeat = false;
      this.#schedule(repeatTiming.delay, 0);
    };
    const letGo = () => {
      this.#held = false;
      window.clearTimeout(this.#holdTimer);
    };
    const ends = ['pointerup', 'pointerleave', 'pointercancel'] as const;
    button.addEventListener('pointerdown', hold);
    ends.forEach((type) => button.addEventListener(type, letGo));
    return () => {
      letGo();
      button.removeEventListener('pointerdown', hold);
      ends.forEach((type) => button.removeEventListener(type, letGo));
    };
  });

  #schedule(seconds: number, count: number) {
    window.clearTimeout(this.#holdTimer);
    this.#holdTimer = window.setTimeout(() => {
      if (!this.#held || this.args.disabled) return;
      this.#didRepeat = true;
      this.args.onClick?.();
      this.#schedule(
        count < 10 ? repeatTiming.interval : repeatTiming.fast,
        count + 1,
      );
    }, seconds * 1000);
  }

  willDestroy() {
    super.willDestroy();
    window.clearTimeout(this.#flashTimer);
    window.clearTimeout(this.#holdTimer);
  }

  <template>
    <button
      type="button"
      class="canon-button canon-button--{{this.kind}}
        {{if this.filled 'canon-button--filled'}}
        {{if this.icon 'canon-button--has-icon'}}
        {{if this.oversized 'canon-button--oversized'}}
        {{unless this.text 'canon-button--symbol'}}"
      data-canon-fit={{if this.fits ""}}
      disabled={{@disabled}}
      aria-label={{this.label}}
      {{press}}
      {{on "click" this.click}}
      {{this.repeat}}
      ...attributes
    >
      {{#let this.icon as |Icon|}}
        {{#if Icon}}
          <span
            class={{if
              this.oversized
              "canon-button-watermark"
              "canon-button-icon"
            }}
            aria-hidden="true"
          ><Icon /></span>
        {{/if}}
      {{/let}}
      {{#if this.text}}
        <span class="canon-button-title">{{this.text}}</span>
      {{/if}}
    </button>
  </template>
}
