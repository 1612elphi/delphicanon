import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';
import '../styles/tokens.css';
import './canon-canvas.css';

export interface CanonCanvasSignature {
  Args: {
    /** Fixed height of the band in px, rules included. */
    height?: number;
    /** Width over height of the content; used when `height` is not set. */
    aspect?: number;
    /** Caps the band's height in a wide column; the content letterboxes itself. */
    maxHeight?: number;
    /** never: always an edge-to-edge band. unlessWide: a band beside a sidebar, a framed box everywhere else. */
    boxing?: 'never' | 'unlessWide';
    /** CSS colour behind the content; default the card colour. */
    background?: string;
    /** Tiles `--canon-pattern` faintly under the content. A CanonSplit banner always has it. */
    pattern?: boolean;
  };
  Blocks: { default: [] };
  Element: HTMLDivElement;
}

/**
 * Edge-to-edge band for a picture, a preview or a drawing surface, ruled
 * above and below. As a page section it spans its column; as a CanonSplit
 * banner it spans every column. Place it between blocks of CanonRows.
 */
export default class CanonCanvas extends Component<CanonCanvasSignature> {
  get style() {
    const { height, aspect, maxHeight, background } = this.args;
    const natural =
      height !== undefined
        ? `${height}px`
        : `calc(100cqw / ${aspect ?? 1} + 2 * var(--canon-frame))`;
    const parts = [`--canon-canvas-natural: ${natural}`];
    if (maxHeight !== undefined)
      parts.push(`--canon-canvas-max: ${maxHeight}px`);
    if (background) parts.push(`--canon-canvas-background: ${background}`);
    return htmlSafe(parts.join('; '));
  }

  <template>
    <div
      class="canon-canvas
        {{if (eq @boxing 'unlessWide') 'canon-canvas--unless-wide'}}
        {{if @pattern 'canon-canvas--pattern'}}"
      style={{this.style}}
      data-canon-height={{@height}}
      data-canon-aspect={{@aspect}}
      ...attributes
    >
      <div class="canon-canvas-content">{{yield}}</div>
    </div>
  </template>
}

function eq(a: unknown, b: unknown) {
  return a === b;
}
