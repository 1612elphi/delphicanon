import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import { clamp, dragSpeed, snap } from '../lib/number.ts';
import '../styles/tokens.css';
import './canon-slider.css';

export interface CanonSliderSignature {
  Args: {
    value: number;
    /** Default 0. A new range clamps the value without calling onChange. */
    min?: number;
    /** Default 1. */
    max?: number;
    /** Snaps the value to multiples of this above `min`. */
    step?: number;
    /** Text of the readout cell; default a percentage of 0 to 1. */
    readout?: (value: number) => string;
    /** Fills from the trailing edge towards the leading one: for amounts that count back from an end. */
    fillsFromTrailing?: boolean;
    labelledBy?: string;
    label?: string;
    /** `dragging` is true for a sideways drag, false for a tap or a key. */
    onChange?: (value: number, dragging: boolean) => void;
  };
  Element: HTMLDivElement;
}

const percent = (value: number) => `${Math.round(value * 100)}%`;

/**
 * Square slider with a readout cell. A tap sets the value; a sideways drag
 * moves it, finer the further the pointer is pulled from the track.
 */
export default class CanonSlider extends Component<CanonSliderSignature> {
  @tracked held?: { value: number; over: number };
  @tracked dragging = false;

  get min() {
    return this.args.min ?? 0;
  }

  get max() {
    return this.args.max ?? 1;
  }

  get span() {
    return this.max - this.min;
  }

  get value(): number {
    const { held } = this;
    const value =
      held && held.over === this.args.value ? held.value : this.args.value;
    return clamp(value, this.min, this.max);
  }

  get readout() {
    return (this.args.readout ?? percent)(this.value);
  }

  get style() {
    const fraction = this.span > 0 ? (this.value - this.min) / this.span : 0;
    return htmlSafe(`--canon-slider-fraction: ${fraction}`);
  }

  apply(raw: number) {
    const next = snap(raw, this.min, this.max, this.args.step);
    if (next === this.value) return;
    this.held = { value: next, over: this.args.value };
    this.args.onChange?.(next, this.dragging);
  }

  key = (event: KeyboardEvent) => {
    const step = this.args.step ?? this.span / 20;
    const next = {
      ArrowRight: this.value + step,
      ArrowUp: this.value + step,
      ArrowLeft: this.value - step,
      ArrowDown: this.value - step,
      Home: this.min,
      End: this.max,
    }[event.key];
    if (next === undefined) return;
    event.preventDefault();
    this.apply(next);
  };

  // template-lint forbids binding pointerdown
  drag = modifier((slider: HTMLElement) => {
    const track = slider.querySelector<HTMLElement>('.canon-slider-track')!;
    let pointer: number | undefined;
    let start = { x: 0, y: 0 };
    let lastX = 0;
    let dragged = 0;

    const backwards = () =>
      (getComputedStyle(slider).direction === 'rtl') !==
      (this.args.fillsFromTrailing ?? false);
    const position = (x: number) => {
      const box = track.getBoundingClientRect();
      if (box.width <= 0) return undefined;
      const unit = clamp((x - box.left) / box.width, 0, 1);
      return this.min + (backwards() ? 1 - unit : unit) * this.span;
    };

    const down = (event: PointerEvent) => {
      if (event.button !== 0) return;
      pointer = event.pointerId;
      start = { x: event.clientX, y: event.clientY };
      this.dragging = false;
      slider.setPointerCapture?.(pointer);
      slider.dataset['active'] = '';
    };
    const move = (event: PointerEvent) => {
      if (event.pointerId !== pointer) return;
      if (!this.dragging) {
        const dx = Math.abs(event.clientX - start.x);
        const at = position(event.clientX);
        if (
          dx <= 4 ||
          dx <= Math.abs(event.clientY - start.y) ||
          at === undefined
        )
          return;
        // absolute first, then relative
        this.dragging = true;
        dragged = at;
        lastX = event.clientX;
        this.apply(dragged);
        return;
      }
      const box = slider.getBoundingClientRect();
      const speed = dragSpeed(
        Math.abs(event.clientY - (box.top + box.height / 2)),
      );
      const width = Math.max(1, track.getBoundingClientRect().width);
      const delta = ((event.clientX - lastX) / width) * this.span * speed;
      lastX = event.clientX;
      dragged = clamp(
        dragged + (backwards() ? -delta : delta),
        this.min,
        this.max,
      );
      this.apply(dragged);
    };
    const end = (event: PointerEvent) => {
      if (event.pointerId !== pointer) return;
      if (event.type === 'pointerup' && !this.dragging) {
        const box = track.getBoundingClientRect();
        const inside =
          event.clientX >= box.left &&
          event.clientX <= box.right &&
          event.clientY >= box.top &&
          event.clientY <= box.bottom;
        const at = position(event.clientX);
        if (inside && at !== undefined) this.apply(at);
      }
      pointer = undefined;
      this.dragging = false;
      delete slider.dataset['active'];
    };

    slider.addEventListener('pointerdown', down);
    slider.addEventListener('pointermove', move);
    slider.addEventListener('pointerup', end);
    slider.addEventListener('pointercancel', end);
    return () => {
      slider.removeEventListener('pointerdown', down);
      slider.removeEventListener('pointermove', move);
      slider.removeEventListener('pointerup', end);
      slider.removeEventListener('pointercancel', end);
    };
  });

  <template>
    <div
      class="canon-slider {{if @fillsFromTrailing 'canon-slider--trailing'}}"
      role="slider"
      tabindex="0"
      aria-labelledby={{@labelledBy}}
      aria-label={{@label}}
      aria-valuemin={{this.min}}
      aria-valuemax={{this.max}}
      aria-valuenow={{this.value}}
      aria-valuetext={{this.readout}}
      style={{this.style}}
      ...attributes
      {{on "keydown" this.key}}
      {{this.drag}}
    >
      <div class="canon-slider-track">
        <div class="canon-slider-fill"></div>
        <div class="canon-slider-marker"></div>
      </div>
      <div
        class="canon-slider-readout"
        aria-hidden="true"
      >{{this.readout}}</div>
    </div>
  </template>
}
