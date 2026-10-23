import type { TOC } from '@ember/component/template-only';
import { htmlSafe } from '@ember/template';
import '../styles/tokens.css';
import './canon-page.css';

export interface CanonPageSignature {
	Args: {
		/** Widest a section gets, in px; null for no cap. Default 720. */
		maxWidth?: number | null;
	};
	Blocks: { default: [] };
	Element: HTMLDivElement;
}

function style(maxWidth: number | null | undefined) {
	return maxWidth === null
		? undefined
		: htmlSafe(`--canon-page-max-width: ${maxWidth ?? 720}px`);
}

/**
 * Scrolling tool body. Sections are centred, capped at maxWidth and inset by
 * the panel padding; a CanonCanvas section spans the full width instead
 * (CanonPage and CanonPaddedSection).
 */
const CanonPage: TOC<CanonPageSignature> = <template>
	<div class="canon-page" style={{style @maxWidth}} ...attributes>
		{{yield}}
	</div>
</template>;

export default CanonPage;
