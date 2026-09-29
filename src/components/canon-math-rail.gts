import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { htmlSafe } from '@ember/template';
import { tracked } from '@glimmer/tracking';
import { modifier } from 'ember-modifier';
import CanonButton from './canon-button.gts';
import { capture } from '../lib/motion.ts';
import type { Key } from '../lib/math/expression.ts';
import '../styles/tokens.css';
import './canon-math-rail.css';

export interface CanonMathRailSignature {
  Args: {
    /** Moves the caret; false when it could not move. */
    onStep?: (key: Key) => boolean;
    short?: boolean;
  };
  Element: HTMLDivElement;
}

export const railHeights = { regular: 44, short: 38 };
/** Sideways drag, in px, per caret place. */
export const stride = 16;
export const arrowWidth = 50;

const chevron = (d: string) => <template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
  ><path d={{d}} /></svg>
</template>;

const arrows = [
  { key: { kind: 'left' }, label: 'Left', icon: chevron('m15 18-6-6 6-6') },
  { key: { kind: 'up' }, label: 'Up', icon: chevron('m18 15-6-6-6 6') },
  { key: { kind: 'down' }, label: 'Down', icon: chevron('m6 9 6 6 6-6') },
  { key: { kind: 'right' }, label: 'Right', icon: chevron('m9 18 6-6-6-6') },
] as const;

/**
 * The caret's controls, under the expression: ribs that slide with a
 * sideways drag, one caret place per stride, then the four arrow keys.
 */
export default class CanonMathRail extends Component<CanonMathRailSignature> {
  @tracked phase = 0;

  get style() {
    return htmlSafe(
      `--canon-math-rail-height: ${this.args.short ? railHeights.short : railHeights.regular}px; --canon-math-arrow-width: ${arrowWidth}px`,
    );
  }

  get ribStyle() {
    return htmlSafe(`--canon-math-rail-phase: ${this.phase}px`);
  }

  step = (key: Key) => this.args.onStep?.(key) ?? false;

  drag = modifier((ribs: HTMLElement) => {
    let last = 0;
    let stepped = 0;
    let start: number | undefined;
    const down = (event: PointerEvent) => {
      if (event.button !== 0) return;
      event.stopPropagation();
      capture(ribs, event.pointerId);
      start = event.clientX;
      last = 0;
      stepped = 0;
    };
    const move = (event: PointerEvent) => {
      if (start === undefined) return;
      const x = event.clientX - start;
      this.phase += x - last;
      last = x;
      while (x - stepped > stride) {
        stepped += stride;
        this.step({ kind: 'right' });
      }
      while (x - stepped < -stride) {
        stepped -= stride;
        this.step({ kind: 'left' });
      }
    };
    const up = () => (start = undefined);
    ribs.addEventListener('pointerdown', down);
    ribs.addEventListener('pointermove', move);
    ribs.addEventListener('pointerup', up);
    ribs.addEventListener('pointercancel', up);
    return () => {
      ribs.removeEventListener('pointerdown', down);
      ribs.removeEventListener('pointermove', move);
      ribs.removeEventListener('pointerup', up);
      ribs.removeEventListener('pointercancel', up);
    };
  });

  <template>
    <div class="canon-math-rail" style={{this.style}} ...attributes>
      <div
        class="canon-math-rail-ribs"
        style={{this.ribStyle}}
        aria-hidden="true"
        {{this.drag}}
      ></div>
      {{#each arrows as |arrow|}}
        <CanonButton
          @kind="cell"
          @icon={{arrow.icon}}
          @label={{arrow.label}}
          @repeats={{true}}
          @onClick={{fn this.step arrow.key}}
        />
      {{/each}}
    </div>
  </template>
}
