import type { TOC } from '@ember/component/template-only';
import '../styles/tokens.css';
import './canon-heading.css';

export interface CanonHeadingSignature {
	Args: { text: string };
	Element: HTMLHeadingElement;
}

const CanonHeading: TOC<CanonHeadingSignature> = <template>
	<h3 class="canon-heading" ...attributes>{{@text}}</h3>
</template>;

export default CanonHeading;
