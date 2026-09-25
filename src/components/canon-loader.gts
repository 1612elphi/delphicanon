import type { TOC } from '@ember/component/template-only';
import { htmlSafe } from '@ember/template';
import '../styles/tokens.css';
import './canon-loader.css';

export type CanonLoaderMode = 'snake' | 'comet' | 'dot' | 'twin' | 'thinking';

export interface CanonLoaderSignature {
  Args: {
    /** Default snake. thinking swings back and forth. */
    mode?: CanonLoaderMode;
    /** Runs anticlockwise; thinking ignores it. */
    reverse?: boolean;
    /** Cell side in px; default 8. */
    cell?: number;
    /** Gap between cells in px; default 2. */
    gap?: number;
  };
  Element: HTMLDivElement;
}

function style(cell = 8, gap = 2) {
  return htmlSafe(
    `--canon-loader-cell: ${cell}px; --canon-loader-gap: ${gap}px`,
  );
}

/**
 * 3 x 3 cell loader in the current colour, the web nds-loader: a lit head
 * runs clockwise round the eight outer cells over a lit centre.
 */
const CanonLoader: TOC<CanonLoaderSignature> = <template>
  <div
    class="canon-loader canon-loader--{{if @mode @mode 'snake'}}
      {{if @reverse 'canon-loader--reverse'}}"
    role="status"
    aria-label="Loading"
    style={{style @cell @gap}}
    ...attributes
  >
    <span style={{htmlSafe "--i: 0"}}></span>
    <span style={{htmlSafe "--i: 1"}}></span>
    <span style={{htmlSafe "--i: 2"}}></span>
    <span style={{htmlSafe "--i: 7"}}></span>
    <i></i>
    <span style={{htmlSafe "--i: 3"}}></span>
    <span style={{htmlSafe "--i: 6"}}></span>
    <span style={{htmlSafe "--i: 5"}}></span>
    <span style={{htmlSafe "--i: 4"}}></span>
  </div>
</template>;

export default CanonLoader;
