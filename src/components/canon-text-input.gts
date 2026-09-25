import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import CanonButton from './canon-button.gts';
import CanonGrid from './canon-grid.gts';
import CanonTextArea from './canon-text-area.gts';
import '../styles/tokens.css';
import './canon-text-input.css';
import { Clipboard as clipboard, Trash as trash } from 'lucide-static';
import CanonIcon from './canon-icon.gts';

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

const PasteIcon = <template><CanonIcon @svg={{clipboard}} /></template>;

const TrashIcon = <template><CanonIcon @svg={{trash}} /></template>;

/** The input block of a text tool: a text area with Paste and Clear under it. */
export default class CanonTextInput extends Component<CanonTextInputSignature> {
  @tracked text = this.args.value ?? '';
  #timer?: number;

  typed = (text: string) => {
    this.text = text;
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
      <CanonTextArea
        @value={{this.text}}
        @placeholder={{if @placeholder @placeholder "Type or paste"}}
        @height={{if @height @height 128}}
        @onChange={{this.typed}}
        aria-label={{if @label @label "Input"}}
      />
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
