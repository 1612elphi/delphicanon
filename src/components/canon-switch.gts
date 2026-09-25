import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import '../styles/tokens.css';
import './canon-switch.css';

export interface CanonSwitchSignature {
  Args: {
    on?: boolean;
    disabled?: boolean;
    onChange?: (on: boolean) => void;
  };
  Element: HTMLInputElement;
}

/** An on/off switch: a native checkbox with the switch role. */
export default class CanonSwitch extends Component<CanonSwitchSignature> {
  // a flip holds until the on arg changes
  @tracked flipped?: { on: boolean; over: boolean | undefined };

  get on(): boolean {
    const { flipped } = this;
    return flipped && flipped.over === this.args.on
      ? flipped.on
      : (this.args.on ?? false);
  }

  change = (event: Event) => {
    const on = (event.target as HTMLInputElement).checked;
    this.flipped = { on, over: this.args.on };
    this.args.onChange?.(on);
  };

  <template>
    <input
      type="checkbox"
      role="switch"
      class="canon-switch"
      checked={{this.on}}
      aria-checked={{if this.on "true" "false"}}
      disabled={{@disabled}}
      ...attributes
      {{on "change" this.change}}
    />
  </template>
}
