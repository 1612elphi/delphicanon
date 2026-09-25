import Component from '@glimmer/component';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import press from '../modifiers/canon-press.ts';
import type CanonToastService from '../services/canon-toast.ts';
import '../styles/tokens.css';
import './canon-value-line.css';
import { Copy as copy } from 'lucide-static';
import CanonIcon from './canon-icon.gts';

export type CanonValueLineLayout = 'beside' | 'above' | 'wrapping' | 'numbered';

export interface CanonValueLineSignature {
  Args: {
    label: string;
    /** Null or undefined shows a dash and turns copying off. */
    value?: string | null;
    /**
     * beside: the label in a column `labelWidth` wide, the value on one line.
     * above: the label over the value. wrapping: the label as wide as it is,
     * the value wrapping by character. numbered: a list index as the label.
     */
    layout?: CanonValueLineLayout;
    /** Width of the label column in px for `beside`; fit it to the longest label among sibling lines. */
    labelWidth?: number;
    /** For `numbered`: a long value wraps by character instead of being cut off. */
    wraps?: boolean;
    /** Seconds after a change before the new value fades in; unset changes it at once. */
    fadeDelay?: number;
    /** Marks the chosen line of a list. */
    lit?: boolean;
    /** CSS colour for each character of the value; unset sets the value in one colour. */
    tint?: (character: string) => string;
    disabled?: boolean;
  };
  Element: HTMLButtonElement;
}

const CopyGlyph = <template><CanonIcon @svg={{copy}} /></template>;

const dash = '—';
const shownBefore = new WeakMap<HTMLElement, string>();

/** The old value stays for the delay, then crossfades to the new one. */
const fade = modifier(
  (element: HTMLElement, [text, delay]: [string, number | undefined]) => {
    const before = shownBefore.get(element);
    shownBefore.set(element, text);
    if (delay === undefined || before === undefined || before === text) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    const ghost = document.createElement('span');
    ghost.className = 'canon-value-line-value canon-value-line-ghost';
    ghost.textContent = before;
    ghost.setAttribute('aria-hidden', 'true');
    Object.assign(ghost.style, {
      insetInlineStart: `${element.offsetLeft}px`,
      insetBlockStart: `${element.offsetTop}px`,
      inlineSize: `${element.offsetWidth}px`,
    });
    element.after(ghost);
    const duration =
      parseFloat(
        getComputedStyle(element).getPropertyValue('--canon-value-line-fade'),
      ) || 250;
    const timing = { duration, delay: delay * 1000 };
    element.animate({ opacity: [0, 1] }, { ...timing, fill: 'backwards' });
    ghost
      .animate({ opacity: [1, 0] }, { ...timing, fill: 'forwards' })
      .finished.catch(() => undefined)
      .finally(() => ghost.remove());
  },
);

/** A name and a value in a flush cell; a tap copies the value and confirms with the toast. */
export default class CanonValueLine extends Component<CanonValueLineSignature> {
  @service('canon-toast') declare toast: CanonToastService;

  get layout() {
    return this.args.layout ?? 'beside';
  }

  get shown() {
    return this.args.value ?? dash;
  }

  get disabled() {
    return this.args.disabled || this.args.value == null;
  }

  get characters() {
    const { tint } = this.args;
    return tint
      ? [...this.shown].map((character) => ({
          character,
          style: htmlSafe(`color: ${tint(character)}`),
        }))
      : undefined;
  }

  get ariaLabel() {
    return this.layout === 'numbered'
      ? this.shown
      : `${this.args.label} ${this.shown}`;
  }

  get style() {
    return htmlSafe(
      `--canon-value-line-label: ${this.args.labelWidth ?? 48}px`,
    );
  }

  copy = () => void this.toast.copy(this.shown);

  <template>
    <button
      type="button"
      class="canon-value-line canon-value-line--{{this.layout}}
        {{if @wraps 'canon-value-line--wraps'}}
        {{if @lit 'canon-value-line--lit'}}"
      style={{this.style}}
      aria-label={{this.ariaLabel}}
      aria-current={{if @lit "true"}}
      disabled={{this.disabled}}
      {{press}}
      {{on "click" this.copy}}
      ...attributes
    >
      <span class="canon-value-line-label">{{@label}}</span>
      <span class="canon-value-line-value" {{fade this.shown @fadeDelay}}>{{#if
          this.characters
        }}{{#each this.characters as |c|}}<span
              style={{c.style}}
            >{{c.character}}</span>{{/each}}{{else}}{{this.shown}}{{/if}}</span>
      <span class="canon-value-line-glyph" aria-hidden="true"><CopyGlyph
        /></span>
    </button>
  </template>
}
