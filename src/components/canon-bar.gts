import type { TOC } from '@ember/component/template-only';
import { htmlSafe } from '@ember/template';
import '../styles/tokens.css';
import './canon-bar.css';

export interface CanonBarSignature {
	Args: {
		/** Filled share of the width, 0 to 1. */
		share: number;
		/** CSS colour of the fill; default the primary colour. */
		fill?: string;
		/** CSS colour of the track; default the muted colour. */
		track?: string;
	};
	Element: HTMLDivElement;
}

function style(share: number, fill?: string, track?: string) {
	const parts = [`--canon-bar-share: ${Math.min(Math.max(share, 0), 1)}`];
	if (fill) parts.push(`--canon-bar-fill: ${fill}`);
	if (track) parts.push(`--canon-bar-track: ${track}`);
	return htmlSafe(parts.join('; '));
}

/** A bar filled from the leading edge. */
const CanonBar: TOC<CanonBarSignature> = <template>
	<div
		class="canon-bar"
		style={{style @share @fill @track}}
		...attributes
	><div class="canon-bar-fill"></div></div>
</template>;

export default CanonBar;
