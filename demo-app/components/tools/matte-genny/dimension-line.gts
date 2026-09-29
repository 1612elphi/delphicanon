import type { TOC } from '@ember/component/template-only';
import type { SafeString } from '@ember/template';
import CanonFigure from '#src/components/canon-figure.gts';

export interface DimensionLineSignature {
  Args: {
    pixels: number;
    /** Turned a quarter, reading upwards, beside the leading side of what it measures. */
    down?: boolean;
    /** Position and size, before the turn. */
    frame: SafeString;
  };
}

const text = (pixels: number) => String(pixels);

/** A measured span: a rule with end ticks along its bottom edge, the pixel figure centred above it. */
const DimensionLine: TOC<DimensionLineSignature> = <template>
  <span
    class="matte-dimension {{if @down 'matte-dimension--down'}}"
    style={{@frame}}
    aria-hidden="true"
  >
    <CanonFigure
      class="matte-dimension-figure"
      @text={{text @pixels}}
      @unit="px"
      @size={{17}}
      @halo="var(--canon-muted)"
    />
  </span>
</template>;

export default DimensionLine;
