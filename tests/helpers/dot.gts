import type { TOC } from '@ember/component/template-only';

/** A stand-in icon. */
const Dot: TOC<{ Args: object }> = <template>
	<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="6" /></svg>
</template>;

export default Dot;
