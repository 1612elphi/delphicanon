import type { TOC } from '@ember/component/template-only';
import '../styles/tokens.css';
import './canon-rule.css';

export interface CanonRuleSignature {
	Args: { vertical?: boolean };
	Element: HTMLDivElement;
}

const CanonRule: TOC<CanonRuleSignature> = <template>
	<div
		class="canon-rule {{if @vertical 'canon-rule--vertical'}}"
		role="separator"
		aria-orientation={{if @vertical "vertical" "horizontal"}}
		...attributes
	></div>
</template>;

export default CanonRule;
