import type { TOC } from '@ember/component/template-only';
import { htmlSafe } from '@ember/template';

export interface CanonIconSignature {
  Args: {
    /** A lucide-static icon string, `import { Copy } from 'lucide-static'`. */
    svg: string;
  };
}

// lucide's fixed 24 px size would override the CSS box the call site gives the svg
const unsized = (svg: string) =>
  htmlSafe(svg.replace(/\s(?:width|height)="24"/g, ''));

const CanonIcon: TOC<CanonIconSignature> = <template>
  {{unsized @svg}}
</template>;

export default CanonIcon;
