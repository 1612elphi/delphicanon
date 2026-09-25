import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import { compareSpring, springEasing } from '../lib/motion.ts';
import sidewaysPan from '../modifiers/canon-sideways-pan.ts';
import '../styles/tokens.css';
import './canon-image-compare.css';
import { ArrowLeftRight as arrowLeftRight } from 'lucide-static';
import CanonIcon from './canon-icon.gts';

export interface CanonImageCompareSignature {
  Args: {
    /** URL of the original. */
    before?: string;
    /** URL of the result. */
    after?: string;
    /** The result could not be made: the original dims and `failure` shows. */
    failed?: boolean;
    /** Shown over the original when `failed`. */
    failure?: string;
    beforeTitle?: string;
    afterTitle?: string;
  };
  Element: HTMLDivElement;
}

const tapEasing = springEasing(compareSpring.damping);
const nudge = 0.1;

const Grip = <template><CanonIcon @svg={{arrowLeftRight}} /></template>;

/**
 * One picture, the original on the leading side of a draggable divider and
 * the result on the other; a tap moves the divider. To assistive technology
 * it is a slider.
 */
export default class CanonImageCompare extends Component<CanonImageCompareSignature> {
  /** Share of the width that shows the original. */
  @tracked split = 0.5;
  @tracked springs = false;
  #dragged = false;

  get comparing() {
    return Boolean(this.args.before && this.args.after);
  }

  get beforeTitle() {
    return this.args.beforeTitle ?? 'Before';
  }

  get afterTitle() {
    return this.args.afterTitle ?? 'After';
  }

  get percent() {
    return Math.round(this.split * 100);
  }

  get style() {
    const parts = [`--canon-compare-split: ${this.split}`];
    if (this.springs)
      parts.push(
        `--canon-compare-transition: ${compareSpring.ms}ms ${tapEasing}`,
      );
    return htmlSafe(parts.join('; '));
  }

  move(element: HTMLElement, clientX: number, springs: boolean) {
    const box = element.getBoundingClientRect();
    if (box.width <= 0 || !this.comparing) return;
    let share = (clientX - box.left) / box.width;
    if (getComputedStyle(element).direction === 'rtl') share = 1 - share;
    this.springs =
      springs && !window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    this.split = Math.min(Math.max(share, 0), 1);
  }

  onBegin = () => {
    this.#dragged = true;
  };

  onMove = (event: PointerEvent) => {
    this.move(event.currentTarget as HTMLElement, event.clientX, false);
  };

  onClick = (event: MouseEvent) => {
    if (this.#dragged) {
      this.#dragged = false;
      return;
    }
    this.move(event.currentTarget as HTMLElement, event.clientX, true);
  };

  onKey = (event: KeyboardEvent) => {
    if (!this.comparing) return;
    const element = event.currentTarget as HTMLElement;
    const sign = getComputedStyle(element).direction === 'rtl' ? -1 : 1;
    const steps: Record<string, number> = {
      ArrowRight: nudge * sign,
      ArrowLeft: -nudge * sign,
      ArrowUp: nudge,
      ArrowDown: -nudge,
      Home: -1,
      End: 1,
    };
    const step = steps[event.key];
    if (step === undefined) return;
    event.preventDefault();
    this.springs = false;
    this.split = Math.min(Math.max(this.split + step, 0), 1);
  };

  <template>
    {{! template-lint-disable no-invalid-interactive }}
    <div
      class="canon-image-compare
        {{if this.comparing 'canon-image-compare--comparing'}}
        {{if @failed 'canon-image-compare--failed'}}"
      style={{this.style}}
      role={{if this.comparing "slider"}}
      tabindex={{if this.comparing "0"}}
      aria-label="{{this.beforeTitle}}, {{this.afterTitle}}"
      aria-valuemin={{if this.comparing "0"}}
      aria-valuemax={{if this.comparing "100"}}
      aria-valuenow={{if this.comparing this.percent}}
      aria-valuetext={{if this.comparing (percentText this.percent)}}
      {{sidewaysPan onBegin=this.onBegin onMove=this.onMove}}
      {{on "click" this.onClick}}
      {{on "keydown" this.onKey}}
      ...attributes
    >
      {{#if @before}}
        <img
          class="canon-image-compare-before"
          src={{@before}}
          alt=""
          draggable="false"
        />
      {{/if}}
      {{#if this.comparing}}
        <div class="canon-image-compare-after">
          <img src={{@after}} alt="" draggable="false" />
        </div>
        <div class="canon-image-compare-divider"></div>
        <div class="canon-image-compare-grip"><Grip /></div>
        <span
          class="canon-image-compare-tag canon-image-compare-tag--before"
        >{{this.beforeTitle}}</span>
        <span
          class="canon-image-compare-tag canon-image-compare-tag--after"
        >{{this.afterTitle}}</span>
      {{/if}}
      {{#if @failed}}
        <p class="canon-image-compare-failure" role="status">{{@failure}}</p>
      {{/if}}
    </div>
  </template>
}

function percentText(percent: number) {
  return `${percent}%`;
}
