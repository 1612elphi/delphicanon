import type { TOC } from '@ember/component/template-only';
import { htmlSafe } from '@ember/template';
import '../styles/tokens.css';
import './canon-detent-wheel-row.css';

export interface CanonDetentWheelRowSignature {
  Args: {
    /** From CanonDetentWheel's block: 1 on the centre line, 0 a row or more away. */
    focus: number;
  };
  Blocks: { default: [] };
  Element: HTMLDivElement;
}

function focusStyle(focus: number) {
  return htmlSafe(`--canon-detent-focus: ${focus}`);
}

/** A centred label for a CanonDetentWheel row that brightens as it nears the centre line. */
const CanonDetentWheelRow: TOC<CanonDetentWheelRowSignature> = <template>
  <div
    class="canon-detent-wheel-row"
    style={{focusStyle @focus}}
    ...attributes
  >{{yield}}</div>
</template>;

export default CanonDetentWheelRow;
