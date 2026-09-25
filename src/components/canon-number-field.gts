import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import CanonStepper from './canon-stepper.gts';
import { clamp, parseInteger } from '../lib/number.ts';
import '../styles/tokens.css';

export interface CanonNumberFieldSignature {
  Args: {
    value: number;
    min?: number;
    max?: number;
    step?: number;
    /** Muted, after the number. */
    unit?: string;
    /** Id of the element that names the field, such as a row title. */
    labelledBy?: string;
    label?: string;
    disabled?: boolean;
    onChange?: (value: number) => void;
  };
  Element: HTMLDivElement;
}

/** Integer with step buttons either side. Arrow keys step too. */
export default class CanonNumberField extends Component<CanonNumberFieldSignature> {
  // a change holds until the value arg changes
  @tracked held?: { value: number; over: number };
  @tracked draft?: string;

  get min() {
    return this.args.min ?? 0;
  }

  get max() {
    return this.args.max ?? Number.MAX_SAFE_INTEGER;
  }

  get value(): number {
    const { held } = this;
    const value =
      held && held.over === this.args.value ? held.value : this.args.value;
    return clamp(value, this.min, this.max);
  }

  get text() {
    return this.draft ?? String(this.value);
  }

  commit(value: number) {
    if (value === this.value) return;
    this.held = { value, over: this.args.value };
    this.args.onChange?.(value);
  }

  nudge = (direction: -1 | 1) => {
    this.draft = undefined;
    this.commit(
      clamp(this.value + direction * (this.args.step ?? 1), this.min, this.max),
    );
  };

  typed = (event: Event) => {
    this.draft = (event.target as HTMLInputElement).value;
    const value = parseInteger(this.draft);
    if (value !== undefined && value >= this.min && value <= this.max)
      this.commit(value);
  };

  key = (event: KeyboardEvent) => {
    if (event.key === 'Enter') (event.target as HTMLInputElement).blur();
    if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown') return;
    event.preventDefault();
    this.nudge(event.key === 'ArrowUp' ? 1 : -1);
  };

  leave = () => {
    this.draft = undefined;
  };

  <template>
    <CanonStepper
      class="canon-number-field"
      @onStep={{this.nudge}}
      @disabled={{@disabled}}
      ...attributes
    >
      <span class="canon-stepper-value">
        {{! template-lint-disable require-input-label no-redundant-role }}
        <input
          type="text"
          class="canon-stepper-field"
          role="spinbutton"
          aria-valuenow={{this.value}}
          aria-valuemin={{this.min}}
          aria-valuemax={{this.max}}
          inputmode={{if (negative this.min) "text" "numeric"}}
          enterkeyhint="done"
          aria-labelledby={{@labelledBy}}
          aria-label={{@label}}
          value={{this.text}}
          disabled={{@disabled}}
          {{on "input" this.typed}}
          {{on "keydown" this.key}}
          {{on "blur" this.leave}}
        />
        {{#if @unit}}<span class="canon-stepper-unit">{{@unit}}</span>{{/if}}
      </span>
    </CanonStepper>
  </template>
}

function negative(value: number) {
  return value < 0;
}
