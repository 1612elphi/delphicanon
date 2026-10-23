import type { TOC } from '@ember/component/template-only';
import { on } from '@ember/modifier';
import CanonStepper from './canon-stepper.gts';
import '../styles/tokens.css';
import './canon-big-number-field.css';

export interface CanonBigNumberFieldSignature {
	Args: {
		/** The field's text; the tool parses it and sets it. */
		value?: string;
		placeholder?: string;
		/** Centred under the number. */
		unit?: string;
		/** Called with -1 or 1 by the step buttons (repeating while held) and the arrow keys. */
		onStep: (direction: -1 | 1) => void;
		/** Called on every edit with the typed text. */
		onInput?: (text: string) => void;
		/** Typing ended: the field lost focus or Return was pressed. */
		onEndEditing?: () => void;
		labelledBy?: string;
		label?: string;
		disabled?: boolean;
	};
	Element: HTMLDivElement;
}

function typed(onInput?: (text: string) => void) {
	return (event: Event) =>
		onInput?.((event.target as HTMLInputElement).value);
}

function keys(onStep: (direction: -1 | 1) => void) {
	return (event: KeyboardEvent) => {
		if (event.key === 'Enter')
			(event.target as HTMLInputElement).blur();
		if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown')
			return;
		event.preventDefault();
		onStep(event.key === 'ArrowUp' ? 1 : -1);
	};
}

function ended(onEndEditing?: () => void) {
	return () => onEndEditing?.();
}

/** A tool's main number, large and centred over its unit, between step buttons. */
const CanonBigNumberField: TOC<CanonBigNumberFieldSignature> = <template>
	<CanonStepper
		class="canon-big-number-field"
		@onStep={{@onStep}}
		@disabled={{@disabled}}
		...attributes
	>
		<span class="canon-big-number-field-stack">
			{{! template-lint-disable require-input-label }}
			<input
				type="text"
				class="canon-big-number-field-input"
				inputmode="decimal"
				enterkeyhint="done"
				autocomplete="off"
				spellcheck="false"
				value={{@value}}
				placeholder={{@placeholder}}
				aria-labelledby={{@labelledBy}}
				aria-label={{@label}}
				disabled={{@disabled}}
				{{on "input" (typed @onInput)}}
				{{on "keydown" (keys @onStep)}}
				{{on "blur" (ended @onEndEditing)}}
			/>
			{{#if @unit}}
				<span
					class="canon-big-number-field-unit"
				>{{@unit}}</span>
			{{/if}}
		</span>
	</CanonStepper>
</template>;

export default CanonBigNumberField;
