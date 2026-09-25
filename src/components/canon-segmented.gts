import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import type { ComponentLike } from '@glint/template';
import CanonButton from './canon-button.gts';
import CanonGrid from './canon-grid.gts';
import '../styles/tokens.css';

export interface CanonSegmentedSignature {
  Args: {
    /** Titles; with `icons`, what assistive technology reads. */
    items: string[];
    /** Cells that show a symbol instead of the title, one per item. */
    icons?: ComponentLike[];
    selected?: number;
    columns?: number;
    boxed?: boolean;
    disabled?: boolean;
    /** Indices of choices that cannot be taken now; they stay, greyed. */
    disabledIndices?: number[];
    onChange?: (index: number) => void;
  };
  Element: HTMLDivElement;
}

/** Single selection from a flush grid of cells. */
export default class CanonSegmented extends Component<CanonSegmentedSignature> {
  // a pick holds until the selected arg changes
  @tracked picked?: { index: number; over: number | undefined };

  get selected(): number {
    const { picked } = this;
    return picked && picked.over === this.args.selected
      ? picked.index
      : (this.args.selected ?? 0);
  }

  get cells() {
    return this.args.items.map((title, index) => ({
      index,
      title,
      icon: this.args.icons?.[index],
      selected: index === this.selected,
      disabled:
        this.args.disabled === true ||
        (this.args.disabledIndices?.includes(index) ?? false),
    }));
  }

  pick = (index: number) => {
    if (index === this.selected) return;
    this.picked = { index, over: this.args.selected };
    this.args.onChange?.(index);
  };

  <template>
    <CanonGrid
      class="canon-segmented"
      role="radiogroup"
      @columns={{@columns}}
      @boxed={{@boxed}}
      ...attributes
    >
      {{#each this.cells as |cell|}}
        <CanonButton
          role="radio"
          aria-checked={{if cell.selected "true" "false"}}
          @kind="segment"
          @text={{if cell.icon "" cell.title}}
          @icon={{cell.icon}}
          @label={{cell.title}}
          @selected={{cell.selected}}
          @disabled={{cell.disabled}}
          @onClick={{fn this.pick cell.index}}
        />
      {{/each}}
    </CanonGrid>
  </template>
}
