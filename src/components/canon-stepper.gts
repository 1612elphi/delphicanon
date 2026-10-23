import type { TOC } from '@ember/component/template-only';
import { fn } from '@ember/helper';
import CanonButton from './canon-button.gts';
import { Minus, Plus } from '../lib/control-icons.gts';
import '../styles/tokens.css';
import './canon-stepper.css';

export interface CanonStepperSignature {
	Args: {
		/** Called with -1 or 1; repeats while a button is held. */
		onStep: (direction: -1 | 1) => void;
		disabled?: boolean;
	};
	/** The middle cell, usually a field and its unit. A click anywhere in it focuses the field. */
	Blocks: { default: [] };
	Element: HTMLDivElement;
}

/** Minus and plus cells either side of a field's cell, divided by hairlines. */
const CanonStepper: TOC<CanonStepperSignature> = <template>
	<div class="canon-stepper" ...attributes>
		<CanonButton
			class="canon-stepper-minus"
			@kind="cell"
			@icon={{Minus}}
			@label="Decrease"
			@repeats={{true}}
			@disabled={{@disabled}}
			@onClick={{fn @onStep -1}}
		/>
		{{! template-lint-disable require-input-label }}
		<label class="canon-stepper-centre">{{yield}}</label>
		<CanonButton
			class="canon-stepper-plus"
			@kind="cell"
			@icon={{Plus}}
			@label="Increase"
			@repeats={{true}}
			@disabled={{@disabled}}
			@onClick={{fn @onStep 1}}
		/>
	</div>
</template>;

export default CanonStepper;
