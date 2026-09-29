import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import CanonDialog, { type CanonDialogClose } from './canon-dialog.gts';
import CanonGrid from './canon-grid.gts';
import press from '../modifiers/canon-press.ts';
import { appearDelay, jumpColumns } from '../lib/jump.ts';
import { reducedMotion, springEasing } from '../lib/motion.ts';
import '../styles/tokens.css';
import './canon-jump-grid.css';

export interface CanonJumpSection {
  title: string;
  /** Under the title, as a count of the group's items. */
  detail?: string;
}

export interface CanonJumpGridSignature {
  Args: {
    open: boolean;
    sections: CanonJumpSection[];
    /** The lit tile: the group in view. It takes focus when the grid opens. */
    current?: number;
    /** The dialog's accessible name; default Sections. */
    label?: string;
    /** A tile was picked; called after the grid has closed and focus has returned. */
    onPick?: (index: number) => void;
    /** Every close. The owner sets `open` false here. */
    onClose?: () => void;
  };
  Element: HTMLDialogElement;
}

// iOS crossDissolve: no scale
class FadingDialog extends CanonDialog {
  keyframes(): Keyframe[] {
    return [{ opacity: 0 }, { opacity: 1 }];
  }
}

const tileSpring = springEasing(0.7);

const appear = modifier(
  (tile: HTMLElement, [index, count, current]: [number, number, number]) => {
    if (reducedMotion()) return;
    tile.animate(
      [
        { opacity: 0, transform: 'scale(0.8) rotate(-0.05rad)' },
        { opacity: 1, transform: 'none' },
      ],
      {
        duration: 450,
        delay: appearDelay(index, count, current),
        easing: tileSpring,
        fill: 'backwards',
      },
    );
  },
);

/**
 * The Windows Phone jump list: every group of a long list as a tile over
 * the page, the group in view lit. A pick closes it and reports the group;
 * a click beside the tiles or Escape closes it.
 */
export default class CanonJumpGrid extends Component<CanonJumpGridSignature> {
  @tracked columns = jumpColumns(window.innerWidth);

  get current() {
    return this.args.current ?? 0;
  }

  get tiles() {
    return this.args.sections.map((section, index) => ({
      ...section,
      index,
      value: String(index),
      lit: index === this.args.current,
    }));
  }

  measure = modifier((holder: HTMLElement) => {
    const observer = new ResizeObserver(([entry]) => {
      const columns = jumpColumns(entry?.contentRect.width ?? 0);
      if (columns !== this.columns) this.columns = columns;
    });
    observer.observe(holder.closest('dialog') ?? holder);
    return () => observer.disconnect();
  });

  outside = (close: CanonDialogClose, event: MouseEvent) => {
    if (!(event.target as Element).closest('.canon-jump-grid-tile')) close();
  };

  closed = (value: string) => {
    this.args.onClose?.();
    if (value !== '') this.args.onPick?.(Number(value));
  };

  <template>
    <FadingDialog
      class="canon-jump-grid"
      aria-label={{if @label @label "Sections"}}
      @open={{@open}}
      @onClose={{this.closed}}
      ...attributes
    >
      <:default as |close|>
        {{! template-lint-disable no-invalid-interactive }}
        <div
          class="canon-jump-grid-holder"
          {{this.measure}}
          {{on "click" (fn this.outside close)}}
        >
          <CanonGrid @columns={{this.columns}} @boxed={{true}}>
            {{#each this.tiles as |tile|}}
              {{! template-lint-disable no-autofocus-attribute }}
              <button
                type="button"
                class="canon-jump-grid-tile
                  {{if tile.lit 'canon-jump-grid-tile--lit'}}"
                aria-current={{if tile.lit "true"}}
                autofocus={{tile.lit}}
                {{press}}
                {{appear tile.index this.tiles.length this.current}}
                {{on "click" (fn close tile.value)}}
              >
                <span class="canon-jump-grid-title">{{tile.title}}</span>
                {{#if tile.detail}}
                  <span class="canon-jump-grid-detail">{{tile.detail}}</span>
                {{/if}}
              </button>
            {{/each}}
          </CanonGrid>
        </div>
      </:default>
    </FadingDialog>
  </template>
}
