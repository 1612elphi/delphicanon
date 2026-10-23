import type { TOC } from '@ember/component/template-only';
import '../styles/tokens.css';
import './canon-status.css';

export type CanonStatusTone = 'ok' | 'warn' | 'muted';

export interface CanonStatusSignature {
	Args: {
		text: string;
		tone: CanonStatusTone;
		/** A padded row of its own for a CanonRows. */
		row?: boolean;
	};
	Element: HTMLDivElement;
}

/** A short state word in the colour of its tone: ok, warn or muted. */
const CanonStatus: TOC<CanonStatusSignature> = <template>
	<div
		class="canon-status canon-status--{{@tone}}
			{{if @row 'canon-status--row'}}"
		role="status"
		...attributes
	>{{@text}}</div>
</template>;

export default CanonStatus;
