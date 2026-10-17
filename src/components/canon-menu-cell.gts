import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { ChevronsUpDown } from '../lib/control-icons.gts';
import { Hold } from '../lib/hold.ts';
import '../styles/tokens.css';
import './canon-menu-cell.css';

export interface CanonMenuCellSignature {
  Args: {
    items: string[];
    /** Undefined shows the placeholder: a value set elsewhere that matches no choice. */
    selected?: number;
    /** Default an em dash. */
    placeholder?: string;
    labelledBy?: string;
    label?: string;
    disabled?: boolean;
    onChange?: (index: number) => void;
  };
  Element: HTMLDivElement;
}

/**
 * A flush cell that shows one choice and opens the system menu of all of
 * them: a native select laid invisibly over the cell.
 */
export default class CanonMenuCell extends Component<CanonMenuCellSignature> {
  hold = new Hold<number>();

  get selected(): number | undefined {
    return this.hold.read(this.args.selected) ?? this.args.selected;
  }

  get title(): string | undefined {
    const { selected } = this;
    return selected === undefined ? undefined : this.args.items[selected];
  }

  get placeholder() {
    return this.args.placeholder ?? '\u2014';
  }

  get options() {
    return this.args.items.map((title, index) => ({
      title,
      value: String(index),
      selected: index === this.selected,
    }));
  }

  pick = (event: Event) => {
    const index = Number((event.target as HTMLSelectElement).value);
    if (index === this.selected) return;
    this.hold.set(index);
    this.args.onChange?.(index);
  };

  <template>
    <div
      class="canon-menu-cell {{if @disabled 'canon-menu-cell--disabled'}}"
      ...attributes
    >
      <span class="canon-menu-cell-title">{{if
          this.title
          this.title
          this.placeholder
        }}</span>
      <span class="canon-menu-cell-icon" aria-hidden="true"><ChevronsUpDown
        /></span>
      {{! template-lint-disable require-input-label }}
      <select
        class="canon-menu-cell-select"
        aria-labelledby={{@labelledBy}}
        aria-label={{@label}}
        disabled={{@disabled}}
        {{on "change" this.pick}}
      >
        {{#unless this.title}}
          <option
            value=""
            disabled
            selected
            hidden
          >{{this.placeholder}}</option>
        {{/unless}}
        {{#each this.options as |choice|}}
          <option
            value={{choice.value}}
            selected={{choice.selected}}
          >{{choice.title}}</option>
        {{/each}}
      </select>
    </div>
  </template>
}
