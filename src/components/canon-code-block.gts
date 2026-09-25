import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { htmlSafe } from '@ember/template';
import press from '../modifiers/canon-press.ts';
import type CanonToastService from '../services/canon-toast.ts';
import { flashSeconds } from './canon-button.gts';
import '../styles/tokens.css';
import './canon-code-block.css';
import { Check as check, Copy as copy } from 'lucide-static';
import CanonIcon from './canon-icon.gts';

export interface CanonCodeBlockSignature {
  Args: {
    code: string;
    /** Shown uppercased in a heading bar above the code; without it the copy button sits below. */
    language?: string;
    /** Taller code scrolls inside the block. */
    maxHeight?: number;
  };
  Element: HTMLDivElement;
}

const CopyIcon = <template><CanonIcon @svg={{copy}} /></template>;

const CheckIcon = <template><CanonIcon @svg={{check}} /></template>;

/** Monospaced, selectable code with a copy button. Lines do not wrap; the block scrolls sideways. */
export default class CanonCodeBlock extends Component<CanonCodeBlockSignature> {
  @service('canon-toast') declare toast: CanonToastService;
  @tracked copied = false;
  #timer?: number;

  get style() {
    const { maxHeight } = this.args;
    return maxHeight === undefined
      ? undefined
      : htmlSafe(`max-block-size: ${maxHeight}px`);
  }

  copy = async () => {
    try {
      await this.toast.write(this.args.code);
    } catch {
      return;
    }
    if (this.isDestroying) return;
    this.copied = true;
    window.clearTimeout(this.#timer);
    this.#timer = window.setTimeout(() => {
      this.copied = false;
    }, flashSeconds * 1000);
  };

  willDestroy() {
    super.willDestroy();
    window.clearTimeout(this.#timer);
  }

  <template>
    <div
      class="canon-code-block {{if @language 'canon-code-block--titled'}}"
      ...attributes
    >
      <div class="canon-code-block-bar">
        {{#if @language}}
          <span class="canon-code-block-language">{{@language}}</span>
        {{/if}}
        <button
          type="button"
          class="canon-code-block-copy
            {{if this.copied 'canon-code-block-copy--copied'}}"
          aria-label="Copy code"
          {{press}}
          {{on "click" this.copy}}
        >
          {{#if this.copied}}<CheckIcon />{{else}}<CopyIcon />{{/if}}
        </button>
      </div>
      <pre
        class="canon-code-block-code"
        tabindex="0"
        style={{this.style}}
      >{{@code}}</pre>
    </div>
  </template>
}
