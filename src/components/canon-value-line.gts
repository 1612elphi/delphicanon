import Component from '@glimmer/component';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import press from '../modifiers/canon-press.ts';
import type CanonToastService from '../services/canon-toast.ts';
import '../styles/tokens.css';
import './canon-value-line.css';

export interface CanonValueLineSignature {
  Args: {
    label: string;
    value: string;
    /** Width of the label column in px; fit it to the longest label among sibling lines. */
    labelWidth?: number;
  };
  Element: HTMLButtonElement;
}

const CopyGlyph = <template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
  ><rect x="8" y="8" width="14" height="14" rx="2" /><path
      d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"
    /></svg>
</template>;

/** Format name and value in a flush cell; a tap copies the value and confirms with the toast. */
export default class CanonValueLine extends Component<CanonValueLineSignature> {
  @service('canon-toast') declare toast: CanonToastService;

  get style() {
    return htmlSafe(
      `--canon-value-line-label: ${this.args.labelWidth ?? 48}px`,
    );
  }

  copy = () => void this.toast.copy(this.args.value);

  <template>
    <button
      type="button"
      class="canon-value-line"
      style={{this.style}}
      aria-label="{{@label}} {{@value}}"
      {{press}}
      {{on "click" this.copy}}
      ...attributes
    >
      <span class="canon-value-line-label">{{@label}}</span>
      <span class="canon-value-line-value">{{@value}}</span>
      <span class="canon-value-line-glyph" aria-hidden="true"><CopyGlyph
        /></span>
    </button>
  </template>
}
