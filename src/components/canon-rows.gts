import type { TOC } from '@ember/component/template-only';
import '../styles/tokens.css';
import './canon-rows.css';

export interface CanonRowsSignature {
	Args: {
		/** Draws the 2 px tool frame around the rows. */
		framed?: boolean;
	};
	Blocks: { default: [] };
	Element: HTMLDivElement;
}

/** Rows separated by hairlines: the gaps show the border colour. */
const CanonRows: TOC<CanonRowsSignature> = <template>
	<div
		class="canon-rows {{if @framed 'canon-rows--framed'}}"
		...attributes
	>{{yield}}</div>
</template>;

export default CanonRows;
