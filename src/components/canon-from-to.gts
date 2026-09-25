import type { TOC } from '@ember/component/template-only';
import CanonMenuCell from './canon-menu-cell.gts';
import { ArrowRight } from '../lib/control-icons.gts';
import '../styles/tokens.css';
import './canon-from-to.css';

export interface CanonFromToSignature {
  Args: {
    items: string[];
    from?: number;
    to?: number;
    /** Accessible names of the two menus; default From and To. */
    fromLabel?: string;
    toLabel?: string;
    disabled?: boolean;
    onFromChange?: (index: number) => void;
    onToChange?: (index: number) => void;
  };
  Element: HTMLDivElement;
}

/** Two menus of the same choices with an arrow between: a conversion from one to the other. */
const CanonFromTo: TOC<CanonFromToSignature> = <template>
  <div class="canon-from-to" role="group" ...attributes>
    <CanonMenuCell
      @items={{@items}}
      @selected={{@from}}
      @label={{if @fromLabel @fromLabel "From"}}
      @disabled={{@disabled}}
      @onChange={{@onFromChange}}
    />
    <span class="canon-from-to-arrow" aria-hidden="true"><ArrowRight /></span>
    <CanonMenuCell
      @items={{@items}}
      @selected={{@to}}
      @label={{if @toLabel @toLabel "To"}}
      @disabled={{@disabled}}
      @onChange={{@onToChange}}
    />
  </div>
</template>;

export default CanonFromTo;
