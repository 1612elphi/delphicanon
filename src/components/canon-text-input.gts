import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import CanonButton from './canon-button.gts';
import CanonGrid from './canon-grid.gts';
import '../styles/tokens.css';
import './canon-text-input.css';

export interface CanonTextInputSignature {
  Args: {
    /** Starting text; later changes to the arg are not followed. */
    value?: string;
    placeholder?: string;
    /** Height of the text area in px; default 128. */
    height?: number;
    /** Accessible name of the text area; default Input. */
    label?: string;
    /** Typing arrives once it pauses; Paste and Clear arrive at once. */
    onChange?: (text: string) => void;
  };
  Element: HTMLDivElement;
}

/** Seconds typing must pause before `onChange`. */
export const typingDelay = 0.4;

const PasteIcon = <template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
  ><rect width="8" height="4" x="8" y="2" /><path
      d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"
    /></svg>
</template>;

const TrashIcon = <template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
  ><path
      d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"
    /></svg>
</template>;

/** The input block of a text tool: a text area with Paste and Clear under it. */
export default class CanonTextInput extends Component<CanonTextInputSignature> {
  @tracked text = this.args.value ?? '';
  #timer?: number;

  get style() {
    return htmlSafe(`block-size: ${this.args.height ?? 128}px`);
  }

  typed = (event: Event) => {
    this.text = (event.target as HTMLTextAreaElement).value;
    window.clearTimeout(this.#timer);
    this.#timer = window.setTimeout(
      () => this.args.onChange?.(this.text),
      typingDelay * 1000,
    );
  };

  /** Text set from code reaches `onChange` at once. */
  setText(text: string) {
    window.clearTimeout(this.#timer);
    this.text = text;
    this.args.onChange?.(text);
  }

  paste = async () => {
    try {
      const text = await navigator.clipboard.readText();
      if (!this.isDestroying) this.setText(text);
    } catch {
      return;
    }
  };

  clear = () => this.setText('');

  willDestroy() {
    super.willDestroy();
    window.clearTimeout(this.#timer);
  }

  <template>
    <div class="canon-text-input" ...attributes>
      <textarea
        class="canon-text-input-area"
        style={{this.style}}
        placeholder={{if @placeholder @placeholder "Type or paste"}}
        aria-label={{if @label @label "Input"}}
        autocomplete="off"
        autocapitalize="off"
        spellcheck="false"
        value={{this.text}}
        {{on "input" this.typed}}
      ></textarea>
      <CanonGrid>
        <CanonButton
          @text="Paste"
          @icon={{PasteIcon}}
          @onClick={{this.paste}}
        />
        <CanonButton
          @text="Clear"
          @icon={{TrashIcon}}
          @disabled={{if this.text false true}}
          @onClick={{this.clear}}
        />
      </CanonGrid>
    </div>
  </template>
}
