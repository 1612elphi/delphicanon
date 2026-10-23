import type { TOC } from '@ember/component/template-only';
import '../styles/tokens.css';
import './canon-empty-row.css';

export interface CanonEmptyRowSignature {
	Args: { text: string };
	Element: HTMLDivElement;
}

const CanonEmptyRow: TOC<CanonEmptyRowSignature> = <template>
	<div class="canon-empty-row" ...attributes>{{@text}}</div>
</template>;

export default CanonEmptyRow;
