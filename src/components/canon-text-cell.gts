import type { TOC } from '@ember/component/template-only';
import { on } from '@ember/modifier';
import '../styles/tokens.css';
import './canon-text-cell.css';

export interface CanonTextCellSignature {
	Args: {
		value?: string;
		placeholder?: string;
		/** Called on every edit. */
		onChange?: (value: string) => void;
	};
	Element: HTMLInputElement;
}

function edited(onChange: ((value: string) => void) | undefined) {
	return (event: Event) =>
		onChange?.((event.target as HTMLInputElement).value);
}

function blurOnEnter(event: KeyboardEvent) {
	if (event.key === 'Enter') (event.target as HTMLInputElement).blur();
}

/** Text field that meets its row's edges. */
const CanonTextCell: TOC<CanonTextCellSignature> = <template>
	<input
		type="text"
		class="canon-text-cell"
		value={{@value}}
		placeholder={{@placeholder}}
		enterkeyhint="done"
		...attributes
		{{on "input" (edited @onChange)}}
		{{on "keydown" blurOnEnter}}
	/>
</template>;

export default CanonTextCell;
