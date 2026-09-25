import type { TOC } from '@ember/component/template-only';
import {
  ArrowRight as arrowRight,
  ChevronsUpDown as chevronsUpDown,
  Clipboard as clipboard,
  Folder as folder,
  Image as image,
  Minus as minus,
  Pipette as pipette,
  Plus as plus,
} from 'lucide-static';
import CanonIcon from '../components/canon-icon.gts';

type Icon = TOC<{ Args: object }>;

export const Minus: Icon = <template><CanonIcon @svg={{minus}} /></template>;
export const Plus: Icon = <template><CanonIcon @svg={{plus}} /></template>;
export const ChevronsUpDown: Icon = <template>
  <CanonIcon @svg={{chevronsUpDown}} />
</template>;
export const ArrowRight: Icon = <template>
  <CanonIcon @svg={{arrowRight}} />
</template>;
export const Folder: Icon = <template><CanonIcon @svg={{folder}} /></template>;
export const Clipboard: Icon = <template>
  <CanonIcon @svg={{clipboard}} />
</template>;
export const Picture: Icon = <template><CanonIcon @svg={{image}} /></template>;
export const Pipette: Icon = <template>
  <CanonIcon @svg={{pipette}} />
</template>;
