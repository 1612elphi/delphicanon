import type { TOC } from '@ember/component/template-only';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import '../styles/tokens.css';
import './canon-text-area.css';

export interface CanonTextAreaSignature {
	Args: {
		value?: string;
		placeholder?: string;
		/** Fixed height in px; default 200. The text scrolls inside it. */
		height?: number;
		/** Called for typed edits, not for a new `value`. */
		onChange?: (value: string) => void;
	};
	Element: HTMLTextAreaElement;
}

// a model echo must not replace the text being typed
const show = modifier((area: HTMLTextAreaElement, [value]: [string]) => {
	if (document.activeElement !== area && area.value !== value)
		area.value = value;
});

function edited(onChange: ((value: string) => void) | undefined) {
	return (event: Event) =>
		onChange?.((event.target as HTMLTextAreaElement).value);
}

function height(px: number | undefined) {
	return px === undefined ? undefined : htmlSafe(`block-size: ${px}px`);
}

/** Multi-line monospaced input, wrapping, with its own scrolling. */
const CanonTextArea: TOC<CanonTextAreaSignature> = <template>
	<textarea
		class="canon-text-area"
		placeholder={{@placeholder}}
		autocomplete="off"
		autocapitalize="off"
		spellcheck="false"
		style={{height @height}}
		...attributes
		{{show (if @value @value "")}}
		{{on "input" (edited @onChange)}}
	></textarea>
</template>;

export default CanonTextArea;
