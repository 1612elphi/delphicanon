import type { TOC } from '@ember/component/template-only';
import { htmlSafe } from '@ember/template';

/** A gallery icon: pass a lucide SVG imported with `?raw`. */
const Icon: TOC<{ Args: { svg: string } }> = <template>
	{{htmlSafe @svg}}
</template>;

export default Icon;
