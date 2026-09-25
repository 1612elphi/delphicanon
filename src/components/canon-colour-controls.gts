import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import { hex, parseColour, parseHex, type Rgb } from '../lib/colour.ts';
import {
  channels,
  colourAt,
  pointFor,
  solidSpaces,
  spaceNames,
  type SolidPoint,
  type SolidSpace,
} from '../lib/colour-space.ts';
import CanonButton from './canon-button.gts';
import CanonRow from './canon-row.gts';
import CanonRule from './canon-rule.gts';
import CanonSegmented from './canon-segmented.gts';
import '../styles/tokens.css';
import './canon-colour-controls.css';

/**
 * What a CanonColourSolid shows and what its controls change: the Swift
 * controls held the solid itself, so here both read one state. Pass
 * `space`, `point`, `sliceAxis`, `isOrtho` and `showsWhole` to the solid and
 * its picks to `pick`.
 */
export class CanonColourSolidState {
  @tracked space: SolidSpace;
  @tracked point: SolidPoint;
  /** The last change of `point` eases, as after a tap on a slider track; drags and picks follow at once. */
  @tracked animated = false;
  /** The slider row that is the solid's slice; row 3, CMYK's black, never slices. */
  @tracked activeRow: number;
  /** Slices along the active row's channel; false cuts the solid away instead. */
  @tracked slices = true;
  /** The View plane switch. */
  @tracked viewPlane = false;
  /** True while CMYK's black changes. */
  @tracked showsWhole = false;

  constructor({
    space = 'hsl',
    colour = [0.12, 0.4, 0.15],
    activeRow = 0,
  }: { space?: SolidSpace; colour?: Rgb; activeRow?: number } = {}) {
    this.space = space;
    this.point = pointFor(space, colour);
    this.activeRow = activeRow;
  }

  get colour(): Rgb {
    return colourAt(this.space, this.point);
  }

  get isOrtho(): boolean {
    return this.slices && this.viewPlane;
  }

  get sliceAxis(): number | undefined {
    if (!this.slices) return undefined;
    return channels(this.space)[Math.min(this.activeRow, 2)]?.axis;
  }

  setPoint(point: SolidPoint, animated: boolean) {
    this.animated = animated;
    this.point = point;
  }

  /** Eases to `colour`. */
  use(colour: Rgb) {
    this.setPoint(pointFor(this.space, colour), true);
  }

  selectSpace(space: SolidSpace) {
    if (space === this.space) return;
    this.setPoint(pointFor(space, this.colour), false);
    this.space = space;
  }

  /** The solid's change callback. */
  pick = (point: SolidPoint) => this.setPoint(point, false);
}

export interface CanonColourControlsSignature {
  Args: {
    state: CanonColourSolidState;
    /** Title of the notation row; default Any notation. */
    notationTitle?: string;
    /** Leaves out the notation row, for a tool with its own input. */
    hidesNotation?: boolean;
  };
  Element: HTMLDivElement;
}

const spaceTitles = solidSpaces.map((space) => spaceNames[space]);
const typingDelay = 400;
const dragSlop = 3;

const Eyedropper = <template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
  ><path d="m2 22 1-1h3l9-9" /><path d="M3 21v-3l9-9" /><path
      d="m15 6 3.4-3.4a2.1 2.1 0 1 1 3 3L18 9l.4.4a2.1 2.1 0 1 1-3 3l-3.8-3.8a2.1 2.1 0 1 1 3-3l.4.4Z"
    /></svg>
</template>;

/**
 * Rows that drive a CanonColourSolid: any notation beside the system picker,
 * the space, one slider per channel and the View plane switch. The active
 * slider row is the solid's slice. Place it inside a CanonRows.
 */
export default class CanonColourControls extends Component<CanonColourControlsSignature> {
  @tracked typed?: string;
  #typing?: number;
  #dragging = false;
  #picker?: HTMLInputElement;

  get state() {
    return this.args.state;
  }

  get notation() {
    return this.typed ?? hex(this.state.colour);
  }

  get notationFails() {
    return (
      this.typed !== undefined &&
      this.typed.trim() !== '' &&
      !parseColour(this.typed)
    );
  }

  get spaceIndex() {
    return solidSpaces.indexOf(this.state.space);
  }

  get rows() {
    const { state } = this;
    const list = channels(state.space);
    const lit = state.slices ? Math.min(state.activeRow, 2) : -1;
    const longest = list.reduce(
      (a, c) => (c.name.length > a.length ? c.name : a),
      '',
    );
    return list.map((channel, index) => {
      const value = Math.min(
        state.point[channel.axis]! * channel.scale + channel.offset,
        channel.max,
      );
      const fraction = (value - channel.min) / (channel.max - channel.min);
      return {
        index,
        channel,
        value,
        readout: value.toFixed(channel.decimals),
        lit: index === lit,
        longest,
        style: htmlSafe(`--canon-slider-fraction: ${fraction * 100}%`),
      };
    });
  }

  selectSpace = (index: number) => {
    this.state.selectSpace(solidSpaces[index]!);
  };

  slide = (index: number, event: Event) => {
    const channel = channels(this.state.space)[index];
    if (!channel) return;
    if (index < 3) this.state.activeRow = index;
    const value = Number((event.target as HTMLInputElement).value);
    const next = [...this.state.point] as SolidPoint;
    next[channel.axis] = (value - channel.offset) / channel.scale;
    // taps ease, drags follow
    this.state.setPoint(next, !this.#dragging);
  };

  // template-lint forbids binding pointerdown; a touch picks the row there
  touch = modifier((slider: HTMLInputElement, [index]: [number]) => {
    let startX = 0;
    const down = (event: PointerEvent) => {
      startX = event.clientX;
      this.#dragging = false;
      if (index === 3) this.state.showsWhole = true;
      else this.state.activeRow = index;
      window.addEventListener('pointerup', up);
      window.addEventListener('pointercancel', up);
    };
    const move = (event: PointerEvent) => {
      if (Math.abs(event.clientX - startX) > dragSlop) this.#dragging = true;
    };
    const up = () => {
      this.#dragging = false;
      this.state.showsWhole = false;
      window.removeEventListener('pointerup', up);
      window.removeEventListener('pointercancel', up);
    };
    slider.addEventListener('pointerdown', down);
    slider.addEventListener('pointermove', move);
    return () => {
      slider.removeEventListener('pointerdown', down);
      slider.removeEventListener('pointermove', move);
      up();
    };
  });

  type = (event: Event) => {
    this.typed = (event.target as HTMLInputElement).value;
    window.clearTimeout(this.#typing);
    this.#typing = window.setTimeout(this.readNotation, typingDelay);
  };

  readNotation = () => {
    const parsed =
      this.typed === undefined ? undefined : parseColour(this.typed);
    if (parsed) this.state.use(parsed);
  };

  leaveNotation = () => {
    window.clearTimeout(this.#typing);
    this.readNotation();
    this.typed = undefined;
  };

  done = (event: KeyboardEvent) => {
    if (event.key === 'Enter') (event.target as HTMLInputElement).blur();
  };

  keepPicker = modifier((input: HTMLInputElement) => {
    this.#picker = input;
  });

  openPicker = () => {
    const input = this.#picker;
    if (!input) return;
    if ('showPicker' in input) {
      try {
        input.showPicker();
        return;
      } catch {
        // not allowed outside a user gesture in some engines
      }
    }
    input.click();
  };

  picked = (event: Event) => {
    const colour = parseHex((event.target as HTMLInputElement).value);
    if (colour) this.state.use(colour);
  };

  toggleViewPlane = (event: Event) => {
    this.state.viewPlane = (event.target as HTMLInputElement).checked;
  };

  willDestroy() {
    super.willDestroy();
    window.clearTimeout(this.#typing);
  }

  <template>
    <div class="canon-colour-controls" ...attributes>
      {{#unless @hidesNotation}}
        <CanonRow
          @title={{if @notationTitle @notationTitle "Any notation"}}
          @form="stacked"
          as |titleId|
        >
          <div class="canon-colour-controls-notation">
            <input
              type="text"
              class="canon-colour-controls-notation-field
                {{if this.notationFails 'canon-colour-controls-fails'}}"
              value={{this.notation}}
              placeholder="oklch(0.64 0.15 264)"
              spellcheck="false"
              autocomplete="off"
              autocapitalize="off"
              aria-labelledby={{titleId}}
              aria-invalid={{if this.notationFails "true"}}
              {{on "input" this.type}}
              {{on "blur" this.leaveNotation}}
              {{on "keydown" this.done}}
            />
            <CanonRule @vertical={{true}} />
            <CanonButton
              @kind="cell"
              @icon={{Eyedropper}}
              @label="Colour"
              @onClick={{this.openPicker}}
            />
            <input
              type="color"
              class="canon-colour-controls-picker"
              value={{hex this.state.colour}}
              tabindex="-1"
              aria-label="Colour"
              {{this.keepPicker}}
              {{on "input" this.picked}}
            />
          </div>
        </CanonRow>
      {{/unless}}
      <CanonRow @title="Space" @form="stacked">
        <CanonSegmented
          @items={{spaceTitles}}
          @selected={{this.spaceIndex}}
          @columns={{4}}
          @onChange={{this.selectSpace}}
        />
      </CanonRow>
      {{#each this.rows as |row|}}
        <CanonRow
          class="canon-colour-controls-channel
            {{if row.lit 'canon-colour-controls-lit'}}"
          @title={{row.channel.name}}
          @detail={{row.channel.detail}}
          @form="flush"
          @sizingTitle={{row.longest}}
          as |titleId|
        >
          <div class="canon-colour-controls-slider" style={{row.style}}>
            <input
              type="range"
              min={{row.channel.min}}
              max={{row.channel.max}}
              step="any"
              value={{row.value}}
              aria-labelledby={{titleId}}
              aria-valuetext={{row.readout}}
              {{this.touch row.index}}
              {{on "input" (fn this.slide row.index)}}
            />
            <span
              class="canon-colour-controls-readout"
              aria-hidden="true"
            >{{row.readout}}</span>
          </div>
        </CanonRow>
      {{/each}}
      <CanonRow @title="View plane" as |titleId|>
        <input
          type="checkbox"
          role="switch"
          class="canon-colour-controls-switch"
          checked={{this.state.viewPlane}}
          aria-checked={{if this.state.viewPlane "true" "false"}}
          aria-labelledby={{titleId}}
          {{on "change" this.toggleViewPlane}}
        />
      </CanonRow>
    </div>
  </template>
}
