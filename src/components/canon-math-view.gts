import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';
import { htmlSafe } from '@ember/template';
import { drawBox, MathMorph } from '../lib/math/draw.ts';
import { canvasMetrics } from '../lib/math/measure.ts';
import { keyed } from '../lib/math/morph.ts';
import { N, parse, present } from '../lib/math/node.ts';
import { Typesetter, type Box, type Ink } from '../lib/math/typeset.ts';
import '../styles/tokens.css';
import './canon-math-view.css';

export interface CanonMathViewSignature {
  Args: {
    /** nerdamer syntax; text that does not parse is set upright as it is. */
    text?: string;
    /** A box set elsewhere; wins over `text`. */
    box?: Box;
    /** Font size in px; default 22. */
    size?: number;
    ink?: Ink;
    /** Sets a result as written by hand: falling powers, fractions, roots. */
    presents?: boolean;
    /** Placeholder opacity. */
    faint?: boolean;
    /** Every atom in the current colour, as a key label. */
    mono?: boolean;
    /** A change slides the glyphs that stay, grows new ones and fades removed ones. */
    morphs?: boolean;
    /** Accessible name; default the text. */
    label?: string;
  };
  Element: Element;
}

const morphs = new WeakMap<SVGGElement, MathMorph>();

const draw = modifier((svg: SVGSVGElement, [box]: [Box]) => {
  drawBox(svg, box);
});

/**
 * Typeset atoms drawn at their own size, scaled down to fit a narrower
 * frame and centred (CanonMathView). With `morphs`, a change animates
 * through CanonMathMorph.
 */
export default class CanonMathView extends Component<CanonMathViewSignature> {
  get box(): Box {
    if (this.args.box) return this.args.box;
    const setter = new Typesetter(
      canvasMetrics,
      this.args.size ?? 22,
      this.args.ink ?? 'result',
    );
    const text = this.args.text ?? '';
    const node = parse(text);
    return setter.layout(
      node ? (this.args.presents ? present(node) : node) : N.word(text),
    );
  }

  get label() {
    return this.args.label ?? this.args.text;
  }

  get morphStyle() {
    return htmlSafe(`min-block-size: ${Math.ceil(this.box.height)}px`);
  }

  morph = modifier((group: SVGGElement, [box]: [Box]) => {
    const host = group.closest<HTMLElement>('.canon-math-view')!;
    const morph = morphs.get(group) ?? new MathMorph(group);
    morphs.set(group, morph);
    const place = (animated: boolean) => {
      const scale = Math.min(
        1,
        host.clientWidth / Math.max(box.width, 1),
        host.clientHeight / Math.max(box.height, 1),
      );
      const left = (host.clientWidth - box.width * scale) / 2;
      const top =
        (host.clientHeight - box.height * scale) / 2 + box.ascent * scale;
      morph.show(
        keyed(box.atoms, 'view', (atom) => ({
          atom: { ...atom, weight: atom.weight * scale },
          frame: {
            x: left + atom.frame.x * scale,
            y: top + atom.frame.y * scale,
            width: atom.frame.width * scale,
            height: atom.frame.height * scale,
          },
          alpha: 1,
        })),
        animated,
      );
    };
    const drawn = group.childElementCount > 0;
    place(drawn);
    let width = host.clientWidth;
    const resize = new ResizeObserver(() => {
      if (host.clientWidth === width) return;
      width = host.clientWidth;
      place(false);
    });
    resize.observe(host);
    return () => resize.disconnect();
  });

  <template>
    {{#if @morphs}}
      <div
        class="canon-math-view canon-math-view--morph
          {{if @faint 'canon-math-view--faint'}}
          {{if @mono 'canon-math-view--mono'}}"
        style={{this.morphStyle}}
        ...attributes
      >
        <svg role="img" aria-label={{this.label}}><g
            {{this.morph this.box}}
          ></g></svg>
      </div>
    {{else}}
      <svg
        class="canon-math-view
          {{if @faint 'canon-math-view--faint'}}
          {{if @mono 'canon-math-view--mono'}}"
        role="img"
        aria-label={{this.label}}
        {{draw this.box}}
        ...attributes
      ></svg>
    {{/if}}
  </template>
}
