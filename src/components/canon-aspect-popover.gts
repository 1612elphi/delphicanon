import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import { ArrowLeftRight as arrowLeftRight } from 'lucide-static';
import CanonButton from './canon-button.gts';
import CanonGrid from './canon-grid.gts';
import CanonIcon from './canon-icon.gts';
import CanonNumberField from './canon-number-field.gts';
import CanonRow from './canon-row.gts';
import CanonRows from './canon-rows.gts';
import CanonSegmented from './canon-segmented.gts';
import { ChevronsUpDown } from '../lib/control-icons.gts';
import { Hold } from '../lib/hold.ts';
import {
  attach,
  isOpen,
  panelFor,
  type CanonPlacement,
} from '../lib/popover.ts';
import '../styles/tokens.css';
import './canon-popover.css';
import './canon-menu-cell.css';
import './canon-aspect-popover.css';

export interface CanonAspectPreset {
  width: number;
  height: number;
  /** Default `width:height`. */
  label?: string;
}

export interface CanonAspectPopoverSignature {
  Args: {
    width: number;
    height: number;
    onChange?: (width: number, height: number) => void;
    presets?: CanonAspectPreset[];
    /** Largest side; default 9999. */
    max?: number;
    labelledBy?: string;
    label?: string;
    disabled?: boolean;
    /** Default bottom-end. */
    placement?: CanonPlacement;
  };
  Element: HTMLButtonElement;
}

const gcd = (a: number, b: number): number => (b ? gcd(b, a % b) : a);

/** `16:9` for 1920 by 1080; sides that are not whole numbers stay as given. */
export function ratioText(width: number, height: number): string {
  const whole = Number.isInteger(width) && Number.isInteger(height);
  const d = whole && width > 0 && height > 0 ? gcd(width, height) : 1;
  return `${width / d}:${height / d}`;
}

export function sameRatio(
  a: { width: number; height: number },
  b: { width: number; height: number },
): boolean {
  return a.width * b.height === a.height * b.width;
}

/** The largest `width` by `height` rectangle inside a `box` px square. */
export function fitRatio(
  width: number,
  height: number,
  box: number,
): { width: number; height: number } {
  const w = Math.max(width, 1);
  const h = Math.max(height, 1);
  const scale = box / Math.max(w, h);
  return { width: w * scale, height: h * scale };
}

export function shapeOf(width: number, height: number) {
  if (width === height) return 'Square';
  return width > height ? 'Landscape' : 'Portrait';
}

const previewBox = 96;

const Swap = <template><CanonIcon @svg={{arrowLeftRight}} /></template>;

/**
 * A menu-cell trigger showing a width by height ratio, which opens a panel
 * to type both sides, swap them or take a preset, over a preview of the
 * shape. Escape or a click outside closes it; focus goes back to the cell.
 */
export default class CanonAspectPopover extends Component<CanonAspectPopoverSignature> {
  id = `${guidFor(this)}-aspect`;
  valueId = `${guidFor(this)}-aspect-value`;
  hold = new Hold<[number, number]>();

  get pair(): [number, number] {
    return (
      this.hold.read(this.args.width, this.args.height) ?? [
        this.args.width,
        this.args.height,
      ]
    );
  }

  get width() {
    return this.pair[0];
  }

  get height() {
    return this.pair[1];
  }

  get max() {
    return this.args.max ?? 9999;
  }

  get text() {
    return ratioText(this.width, this.height);
  }

  get shape() {
    return shapeOf(this.width, this.height);
  }

  get square() {
    return this.width === this.height;
  }

  get labelledBy() {
    return this.args.labelledBy
      ? `${this.args.labelledBy} ${this.valueId}`
      : undefined;
  }

  get previewStyle() {
    const { width, height } = fitRatio(this.width, this.height, previewBox);
    return htmlSafe(
      `inline-size: ${width.toFixed(1)}px; block-size: ${height.toFixed(1)}px`,
    );
  }

  get presetTitles() {
    return (this.args.presets ?? []).map(
      (p) => p.label ?? `${p.width}:${p.height}`,
    );
  }

  get presetIndex(): number | null {
    const at = (this.args.presets ?? []).findIndex((p) =>
      sameRatio(p, { width: this.width, height: this.height }),
    );
    return at < 0 ? null : at;
  }

  change(width: number, height: number) {
    if (width === this.width && height === this.height) return;
    this.hold.set([width, height]);
    this.args.onChange?.(width, height);
  }

  setWidth = (width: number) => this.change(width, this.height);
  setHeight = (height: number) => this.change(this.width, height);
  swap = () => this.change(this.height, this.width);
  pickPreset = (index: number) => {
    const preset = this.args.presets?.[index];
    if (preset) this.change(preset.width, preset.height);
  };

  trigger = modifier((button: HTMLButtonElement) => {
    const panel = panelFor(button, this.id);
    const detach = attach(panel, button, {
      placement: this.args.placement ?? 'bottom-end',
      invokes: true,
      haspopup: 'dialog',
    });
    const opened = () => {
      if (!isOpen(panel)) return;
      const field = panel.querySelector<HTMLInputElement>('input');
      field?.focus({ preventScroll: true });
      field?.select();
    };
    panel.addEventListener('toggle', opened);
    return () => {
      panel.removeEventListener('toggle', opened);
      detach();
    };
  });

  <template>
    <button
      type="button"
      class="canon-menu-cell canon-aspect-popover-trigger
        {{if @disabled 'canon-menu-cell--disabled'}}"
      aria-labelledby={{this.labelledBy}}
      aria-label={{@label}}
      disabled={{@disabled}}
      {{this.trigger}}
      ...attributes
    >
      <span
        id={{this.valueId}}
        class="canon-menu-cell-title"
      >{{this.text}}</span>
      <span class="canon-menu-cell-icon" aria-hidden="true"><ChevronsUpDown
        /></span>
    </button>
    <div
      id={{this.id}}
      class="canon-popover canon-aspect-popover"
      popover="auto"
      role="dialog"
      aria-label="Aspect ratio"
    >
      <div class="canon-aspect-popover-preview" aria-hidden="true">
        <span
          class="canon-aspect-popover-shape"
          style={{this.previewStyle}}
        ></span>
      </div>
      <CanonRows>
        {{#if @presets}}
          <CanonSegmented
            class="canon-aspect-popover-presets"
            @items={{this.presetTitles}}
            @selected={{this.presetIndex}}
            @onChange={{this.pickPreset}}
          />
        {{/if}}
        <CanonGrid @columns={{2}}>
          <CanonNumberField
            class="canon-aspect-popover-width"
            @value={{this.width}}
            @min={{1}}
            @max={{this.max}}
            @label="Width"
            @onChange={{this.setWidth}}
          />
          <CanonNumberField
            class="canon-aspect-popover-height"
            @value={{this.height}}
            @min={{1}}
            @max={{this.max}}
            @label="Height"
            @onChange={{this.setHeight}}
          />
        </CanonGrid>
        <CanonRow @title={{this.text}} @detail={{this.shape}} @form="flush">
          <CanonButton
            class="canon-aspect-popover-swap"
            @kind="cell"
            @text="Swap"
            @icon={{Swap}}
            @disabled={{this.square}}
            @onClick={{this.swap}}
          />
        </CanonRow>
      </CanonRows>
    </div>
  </template>
}
