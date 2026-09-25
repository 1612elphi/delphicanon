import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import CanonButton from './canon-button.gts';
import { splitForMiddle } from '../lib/files.ts';
import '../styles/tokens.css';
import './canon-file-cell.css';

export interface CanonFileCellSignature {
  Args: {
    /** As the file input's accept attribute; empty takes any file. */
    accept?: string;
    labelledBy?: string;
    disabled?: boolean;
    onChange?: (file: File) => void;
  };
  Element: HTMLDivElement;
}

/** File name beside a Choose cell. */
export default class CanonFileCell extends Component<CanonFileCellSignature> {
  // ponytail: no clear(); re-render the cell to empty it
  @tracked file?: File;
  input?: HTMLInputElement;

  get parts() {
    return this.file ? splitForMiddle(this.file.name) : undefined;
  }

  get head() {
    return this.parts?.[0];
  }

  get tail() {
    return this.parts?.[1];
  }

  keep = modifier((input: HTMLInputElement) => {
    this.input = input;
  });

  choose = () => this.input?.click();

  picked = (event: Event) => {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';
    if (!file) return;
    this.file = file;
    this.args.onChange?.(file);
  };

  <template>
    <div
      class="canon-file-cell"
      role="group"
      aria-labelledby={{@labelledBy}}
      ...attributes
    >
      <span
        class="canon-file-cell-name
          {{unless this.parts 'canon-file-cell-name--none'}}"
      >
        {{#if this.parts}}
          <span class="canon-file-cell-head">{{this.head}}</span>
          <span class="canon-file-cell-tail">{{this.tail}}</span>
        {{else}}
          None
        {{/if}}
      </span>
      <CanonButton
        @kind="cell"
        @text="Choose"
        @disabled={{@disabled}}
        @onClick={{this.choose}}
      />
      {{! template-lint-disable require-input-label }}
      <input
        type="file"
        class="canon-file-cell-input"
        accept={{@accept}}
        hidden
        {{this.keep}}
        {{on "change" this.picked}}
      />
    </div>
  </template>
}
