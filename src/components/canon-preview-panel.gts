import type { TOC } from '@ember/component/template-only';
import '../styles/tokens.css';
import './canon-preview-panel.css';

export interface CanonPreviewPanelSignature {
  Args: {
    caption: string;
    /** Trailing note in the caption row, such as the size. */
    detail?: string;
  };
  Blocks: { default: [] };
  Element: HTMLElement;
}

/** Framed preview: caption row, hairline, then the content flush beneath. */
const CanonPreviewPanel: TOC<CanonPreviewPanelSignature> = <template>
  <figure class="canon-preview-panel" ...attributes>
    <figcaption class="canon-preview-panel-header">
      <span class="canon-preview-panel-caption">{{@caption}}</span>
      {{#if @detail}}
        <span class="canon-preview-panel-detail">{{@detail}}</span>
      {{/if}}
    </figcaption>
    <div class="canon-preview-panel-content">{{yield}}</div>
  </figure>
</template>;

export default CanonPreviewPanel;
