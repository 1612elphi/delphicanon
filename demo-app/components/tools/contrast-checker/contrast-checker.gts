import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import { registerDestructor } from '@ember/destroyable';
import type Owner from '@ember/owner';
import CanonButton from '#src/components/canon-button.gts';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonColourCard from '#src/components/canon-colour-card.gts';
import CanonColourControls, {
  CanonColourSolidState,
} from '#src/components/canon-colour-controls.gts';
import CanonColourSolid from '#src/components/canon-colour-solid.gts';
import CanonColourStrip from '#src/components/canon-colour-strip.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonIcon from '#src/components/canon-icon.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonSplit from '#src/components/canon-split.gts';
import press from '#src/modifiers/canon-press.ts';
import {
  contrastFigure,
  contrastRatio,
  hex,
  parseColour,
  parseHex,
  type Rgb,
} from '#src/lib/colour.ts';
import { solidSpaces, type SolidPoint } from '#src/lib/colour-space.ts';
import { springEasing } from '#src/lib/motion.ts';
import { suggest, targets, type Target } from './contrast.ts';
import Specimen, { specimenHeight } from './specimen.gts';
import { Lamps, Scale } from './verdict.gts';
import './contrast-checker.css';
import contrast from 'lucide-static/icons/contrast.svg?raw';
import arrows from 'lucide-static/icons/arrow-left-right.svg?raw';
import wand from 'lucide-static/icons/wand-sparkles.svg?raw';

export const tool = {
  title: 'Contrast checker',
  group: 'Colour',
  icon: contrast,
};

// ?color=<hex>: the web tool's carried colour, as the foreground
// ?contrastFg=<any notation> ?contrastBg=<any notation> ?contrastWell=1 (background) ?contrastSpace=<picker index>
// ?contrastLater: background well at 2 s, flip at 3.5 s, first suggestion at 5 s (the iOS -contrastlater)
const query = new URLSearchParams(window.location.search);
const colourParam = (key: string) => {
  const text = query.get(key);
  return text ? parseColour(text) : undefined;
};
const carried = query.get('color');
const startForeground =
  colourParam('contrastFg') ??
  (carried ? parseHex(carried) : undefined) ??
  parseHex('EAEAEA')!;
const startBackground = colourParam('contrastBg') ?? parseHex('1A1A2E')!;
const startsOnBackground = query.get('contrastWell') === '1';
const startSpace =
  solidSpaces[Number(query.get('contrastSpace') ?? 3) || 0] ?? 'oklch';

/** Changes closer together than this follow at once, as a drag; ContrastCheckerViewController's 0.12 s. */
const followMs = 120;

// the channel titles beside the sliders truncate at the 340 px default
const sidebarWidth = 400;

const wellsStyle = htmlSafe(`--contrast-well-spring: ${springEasing(0.8)}`);

const swatch = (colour: Rgb) => htmlSafe(`background: ${hex(colour)}`);
const pair = (foreground: Rgb, background: Rgb) =>
  htmlSafe(`color: ${hex(foreground)}; background: ${hex(background)}`);

interface Suggestion {
  target: Target;
  candidate?: Rgb;
  foreground: Rgb;
  background: Rgb;
  title: string;
  detail: string;
  ratio: string;
}

/** The port of ContrastCheckerViewController. */
export default class ContrastChecker extends Component {
  state = new CanonColourSolidState({
    space: startSpace,
    colour: startsOnBackground ? startBackground : startForeground,
    activeRow: 2,
  });
  @tracked editsBackground = startsOnBackground;
  /** The well the solid does not edit. */
  @tracked fixed: Rgb = startsOnBackground ? startForeground : startBackground;
  #lastPick = 0;

  constructor(owner: Owner, args: object) {
    super(owner, args);
    if (!query.has('contrastLater')) return;
    const timers = [
      window.setTimeout(() => this.edit(true), 2000),
      window.setTimeout(() => this.flip(), 3500),
      window.setTimeout(() => {
        const first = this.suggestions.find((row) => row.candidate);
        if (first) this.apply(first);
      }, 5000),
    ];
    registerDestructor(this, () =>
      timers.forEach((timer) => window.clearTimeout(timer)),
    );
  }

  get edited(): Rgb {
    return this.state.colour;
  }

  get foreground(): Rgb {
    return this.editsBackground ? this.fixed : this.edited;
  }

  get background(): Rgb {
    return this.editsBackground ? this.edited : this.fixed;
  }

  get ratio() {
    return contrastRatio(this.foreground, this.background);
  }

  get animated() {
    return this.state.animated;
  }

  get marks() {
    return [this.fixed];
  }

  get wells() {
    return [
      { title: 'Foreground', colour: this.foreground, background: false },
      { title: 'Background', colour: this.background, background: true },
    ].map((well) => ({
      ...well,
      hex: hex(well.colour),
      swatch: swatch(well.colour),
      selected: well.background === this.editsBackground,
    }));
  }

  get suggestions(): Suggestion[] {
    const { foreground, background } = this;
    return targets.map((target) => {
      const candidate = suggest(target, foreground, background);
      const [moving, fixed] = target.background
        ? [background, foreground]
        : [foreground, background];
      const shown = candidate ?? moving;
      const met = contrastRatio(foreground, background) >= target.ratio;
      return {
        target,
        candidate,
        foreground: target.background ? foreground : shown,
        background: target.background ? shown : background,
        title: target.background ? 'Background' : 'Foreground',
        detail: `${target.level} · ${hex(shown)}`,
        ratio: candidate
          ? `${contrastFigure(contrastRatio(candidate, fixed))}:1`
          : met
            ? '✓'
            : '—',
      };
    });
  }

  /** The solid's pick: one after another within 120 ms is a drag and follows at once. */
  pick = (point: SolidPoint) => {
    const now = performance.now();
    const eases = now - this.#lastPick > followMs;
    this.#lastPick = now;
    this.state.setPoint(point, eases);
  };

  /** Hands the solid the other well's colour, eased; the edited colour becomes the fixed one. */
  #trade() {
    const other = this.fixed;
    this.fixed = this.edited;
    this.state.use(other);
  }

  edit = (background: boolean) => {
    if (background === this.editsBackground) return;
    this.editsBackground = background;
    this.#trade();
  };

  flip = () => this.#trade();

  apply = (row: Suggestion) => {
    if (!row.candidate) return;
    if (row.target.background === this.editsBackground) {
      this.state.use(row.candidate);
    } else {
      this.fixed = row.candidate;
      this.state.animated = true;
    }
  };

  <template>
    <CanonSplit
      class="gallery contrast-checker
        {{unless this.animated 'contrast-checker--follows'}}"
      @sidebarWidth={{sidebarWidth}}
    >
      <:banner>
        <CanonCanvas @height={{specimenHeight}}>
          <Specimen
            @foreground={{this.foreground}}
            @background={{this.background}}
            @ratio={{this.ratio}}
            @animated={{this.animated}}
          />
        </CanonCanvas>
      </:banner>
      <:sidebar>
        <CanonRows @framed={{true}}>
          <div class="contrast-wells" style={{wellsStyle}}>
            {{#each this.wells as |well|}}
              <button
                type="button"
                class="contrast-well {{if well.selected 'contrast-well--on'}}"
                aria-pressed={{if well.selected "true" "false"}}
                aria-label="{{well.title}} {{well.hex}}"
                {{press}}
                {{on "click" (fn this.edit well.background)}}
              >
                <span class="contrast-well-swatch" style={{well.swatch}}></span>
                <span class="contrast-well-text">
                  <span class="contrast-well-title">{{well.title}}</span>
                  <span class="contrast-well-hex">{{well.hex}}</span>
                </span>
              </button>
            {{/each}}
            <CanonButton
              class="contrast-flip"
              @kind="cell"
              @icon={{component CanonIcon svg=arrows}}
              @label="Flip"
              @onClick={{this.flip}}
            />
            <span
              class="contrast-wells-indicator
                {{if this.editsBackground 'contrast-wells-indicator--end'}}"
            ></span>
          </div>
          <div class="contrast-solid">
            <CanonColourSolid
              class="contrast-solid-picture"
              @space={{this.state.space}}
              @point={{this.state.point}}
              @animated={{this.state.animated}}
              @sliceAxis={{this.state.sliceAxis}}
              @isOrtho={{this.state.isOrtho}}
              @showsWhole={{this.state.showsWhole}}
              @marks={{this.marks}}
              @onChange={{this.pick}}
            />
            <CanonColourStrip @colour={{this.edited}} />
          </div>
          <CanonColourControls
            @state={{this.state}}
            @notationTitle={{if this.editsBackground "Background" "Foreground"}}
          />
        </CanonRows>
      </:sidebar>
      <:main>
        <CanonRows @framed={{true}}>
          <CanonHeading @text="Contrast ratio" />
          <Scale @ratio={{this.ratio}} />
          <Lamps @ratio={{this.ratio}} />
        </CanonRows>
        <CanonRows @framed={{true}}>
          <CanonHeading @text="Suggestions" />
          {{#each this.suggestions as |row|}}
            <button
              type="button"
              class="contrast-suggestion"
              disabled={{unless row.candidate true}}
              aria-label="{{row.title}} {{row.target.level}}, {{row.detail}}, {{row.ratio}}"
              {{press}}
              {{on "click" (fn this.apply row)}}
            >
              <span
                class="contrast-suggestion-preview"
                style={{pair row.foreground row.background}}
                aria-hidden="true"
              >Aa</span>
              <span class="contrast-suggestion-cell">
                <span class="contrast-suggestion-text">
                  <span class="contrast-suggestion-title">{{row.title}}</span>
                  <span class="contrast-suggestion-detail">{{row.detail}}</span>
                </span>
                <span class="contrast-suggestion-ratio">{{row.ratio}}</span>
                {{#if row.candidate}}
                  <span class="contrast-suggestion-glyph" aria-hidden="true">
                    <CanonIcon @svg={{wand}} />
                  </span>
                {{/if}}
              </span>
            </button>
          {{/each}}
        </CanonRows>
        <div class="contrast-cards">
          <CanonColourCard @colour={{this.foreground}} @name="Foreground" />
          <CanonColourCard @colour={{this.background}} @name="Background" />
        </div>
      </:main>
    </CanonSplit>
  </template>
}
