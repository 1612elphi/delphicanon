import type { TOC } from '@ember/component/template-only';
import CanonFigure from './canon-figure.gts';
import '../styles/tokens.css';
import './canon-dimension-line.css';

export interface CanonDimensionLineSignature {
  Args: {
    pixels: number;
    /** Turned a quarter, reading upwards, beside the leading side of what it measures. */
    down?: boolean;
    /** Muted rule and ticks, no figure: an empty picture keeps a loaded one's frame without stale sizes. */
    blank?: boolean;
  };
  Element: HTMLSpanElement;
}

const text = (pixels: number) => String(pixels);

/**
 * A measured span: a rule with end ticks along its bottom edge, the pixel
 * figure centred above it. Placed by the consumer with inset and size
 * properties (`dimensionLines` in `lib/dimension-line.ts`), before the turn.
 */
const CanonDimensionLine: TOC<CanonDimensionLineSignature> = <template>
  <span
    class="canon-dimension-line
      {{if @down 'canon-dimension-line--down'}}
      {{if @blank 'canon-dimension-line--blank'}}"
    aria-hidden="true"
    ...attributes
  >
    {{#unless @blank}}
      <CanonFigure
        class="canon-dimension-line-figure"
        @text={{text @pixels}}
        @unit="px"
        @size={{17}}
        @halo="var(--canon-muted)"
      />
    {{/unless}}
  </span>
</template>;

export default CanonDimensionLine;
