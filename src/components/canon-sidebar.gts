import type { TOC } from '@ember/component/template-only';
import '../styles/tokens.css';
import './canon-sidebar.css';

export interface CanonSidebarSignature {
  Args: {
    /**
     * true: the icon rail. false: full width at every size. Unset: the rail
     * inside a `canon-window` container narrower than 640 px.
     */
    collapsed?: boolean;
  };
  Blocks: {
    /** A picture above the rows that does not scroll with them. */
    hero: [];
    /** CanonSidebarRows, and CanonHeadings between groups. */
    default: [];
  };
  Element: HTMLElement;
}

function state(collapsed: boolean | undefined) {
  if (collapsed === true) return 'canon-sidebar--collapsed';
  if (collapsed === false) return 'canon-sidebar--expanded';
  return undefined;
}

/**
 * The window's navigation column (Sidebar): 240 px of 44 px rows on the
 * muted background, the gaps between rows and cells showing the border
 * colour, a frame-width rule on the trailing edge.
 */
const CanonSidebar: TOC<CanonSidebarSignature> = <template>
  <nav class="canon-sidebar {{state @collapsed}}" ...attributes>
    {{#if (has-block "hero")}}
      <div class="canon-sidebar-hero">{{yield to="hero"}}</div>
    {{/if}}
    <div class="canon-sidebar-scroll">
      <div class="canon-sidebar-rows">{{yield}}</div>
    </div>
  </nav>
</template>;

export default CanonSidebar;
