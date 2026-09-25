import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
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
    /**
     * Takes the band's height from the content's own height at the column's
     * width, plus the rules; content with no height hides the band.
     */
    fitting?: boolean;
    /** With `fitting`: a change of the content's height at the same width animates the band. */
    animated?: boolean;
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
  @tracked fitted?: number;
  @tracked eases = false;

  get collapsed() {
    return this.args.fitting && this.fitted === 0;
  }

  get style() {
    const { height, aspect, maxHeight, background } = this.args;
    const natural =
      height !== undefined
        ? `${height}px`
        : `calc(100cqw / ${aspect ?? 1} + 2 * var(--canon-frame))`;
    const parts = [`--canon-canvas-natural: ${natural}`];
    if (this.args.fitting && this.fitted !== undefined)
      parts.push(`--canon-canvas-fitted: ${this.fitted}px`);
    if (maxHeight !== undefined)
      parts.push(`--canon-canvas-max: ${maxHeight}px`);
    if (background) parts.push(`--canon-canvas-background: ${background}`);
    return htmlSafe(parts.join('; '));
  }

  fit = modifier((element: HTMLElement) => {
    let width: number | undefined;
    const observer = new ResizeObserver(([entry]) => {
      const box = entry?.borderBoxSize[0];
      if (!box) return;
      this.eases = Boolean(this.args.animated) && box.inlineSize === width;
      width = box.inlineSize;
      this.fitted = box.blockSize;
    });
    observer.observe(element);
    return () => observer.disconnect();
  });

  <template>
    <div
      class="canon-canvas
        {{if (eq @boxing 'unlessWide') 'canon-canvas--unless-wide'}}
        {{if @pattern 'canon-canvas--pattern'}}
        {{if @fitting 'canon-canvas--fitting'}}
        {{if this.collapsed 'canon-canvas--collapsed'}}
        {{if this.eases 'canon-canvas--eases'}}"
      style={{this.style}}
      data-canon-height={{@height}}
      data-canon-aspect={{@aspect}}
      ...attributes
    >
      <div class="canon-canvas-content">
        {{#if @fitting}}
          <div class="canon-canvas-fit" {{this.fit}}>{{yield}}</div>
        {{else}}
          {{yield}}
        {{/if}}
      </div>
    </div>
  </template>
}

function eq(a: unknown, b: unknown) {
  return a === b;
}
