import Component from '@glimmer/component';
import type Owner from '@ember/owner';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import press from '../modifiers/canon-press.ts';
import CanonMathInput from './canon-math-input.gts';
import CanonMathView from './canon-math-view.gts';
import { Expression, layoutRow, type Key } from '../lib/math/expression.ts';
import { canvasMetrics } from '../lib/math/measure.ts';
import { Typesetter } from '../lib/math/typeset.ts';
import '../styles/tokens.css';
import './canon-math-field.css';
import { Keyboard as keyboard } from 'lucide-static';
import CanonIcon from './canon-icon.gts';

export interface CanonMathFieldSignature {
  Args: {
    /** nerdamer syntax. */
    text?: string;
    /** The letter the keypad offers first, and the variable of derivatives, integrals and limits. */
    variable?: string;
    /** Shown faint while the text is empty, in the same syntax. */
    placeholder?: string;
    /** Font size in px; default 22. */
    size?: number;
    /** Every edit made in the keypad sheet. */
    onChange?: (text: string) => void;
    /** The sheet closed, with the text. */
    onCompletion?: (text: string) => void;
    /** Lets insert keys beside the field open it and type. */
    handle?: CanonMathFieldHandle;
  };
  Element: HTMLButtonElement;
}

/** Opens a CanonMathField from outside it, as `field.edit(then:)` does. */
export class CanonMathFieldHandle {
  field?: CanonMathField;

  /** Opens the keypad sheet, then types `keys`. */
  edit = (keys: Key[] = []) => this.field?.edit(keys);
}

const KeyboardIcon = <template><CanonIcon @svg={{keyboard}} /></template>;

/**
 * An expression typeset in a flush cell; a click opens the keypad sheet
 * (CanonMathField). `onChange` runs on every edit made there, `onCompletion`
 * when the sheet closes.
 */
export default class CanonMathField extends Component<CanonMathFieldSignature> {
  @tracked editing = false;
  @tracked pendingKeys: Key[] = [];
  @tracked edited?: { text: string; over?: string };
  #button?: HTMLButtonElement;

  constructor(owner: Owner, args: CanonMathFieldSignature['Args']) {
    super(owner, args);
    if (args.handle) args.handle.field = this;
  }

  /** The last edit, until the owner passes a different text. */
  get text(): string {
    const edited = this.edited;
    return edited && edited.over === this.args.text
      ? edited.text
      : (this.args.text ?? '');
  }

  get variable() {
    return this.args.variable ?? 'x';
  }

  get box() {
    const shown = this.text || (this.args.placeholder ?? '');
    return layoutRow(
      new Typesetter(canvasMetrics, this.args.size ?? 22, 'result'),
      new Expression(shown, this.variable).root,
      { variable: this.variable },
    );
  }

  get source() {
    return this.#button;
  }

  remember = (button: HTMLButtonElement) => {
    this.#button = button;
  };

  edit(keys: Key[] = []) {
    if (this.editing) return;
    this.pendingKeys = keys;
    this.editing = true;
  }

  open = () => this.edit();

  changed = (text: string) => {
    this.edited = { text, over: this.args.text };
    this.args.onChange?.(text);
  };

  closed = (text: string) => {
    this.edited = { text, over: this.args.text };
    this.editing = false;
    this.args.onCompletion?.(text);
    this.#button?.focus({ preventScroll: true });
  };

  willDestroy() {
    super.willDestroy();
    if (this.args.handle?.field === this) this.args.handle.field = undefined;
  }

  <template>
    <button
      type="button"
      class="canon-math-field {{if this.editing 'canon-math-field--editing'}}"
      aria-label="Expression"
      aria-haspopup="dialog"
      {{press}}
      {{on "click" this.open}}
      {{remember this.remember}}
      ...attributes
    >
      <CanonMathView
        @box={{this.box}}
        @faint={{if this.text false true}}
        @label={{this.text}}
      />
      <span class="canon-math-field-glyph"><KeyboardIcon /></span>
    </button>
    {{#if this.editing}}
      <CanonMathInput
        @text={{this.text}}
        @variable={{this.variable}}
        @keys={{this.pendingKeys}}
        @source={{this.source}}
        @onChange={{this.changed}}
        @onClose={{this.closed}}
      />
    {{/if}}
  </template>
}

const remember = modifier(
  (element: HTMLButtonElement, [keep]: [(e: HTMLButtonElement) => void]) =>
    keep(element),
);
