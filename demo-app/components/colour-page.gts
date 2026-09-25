import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import CanonButton from '#src/components/canon-button.gts';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonColourCard from '#src/components/canon-colour-card.gts';
import CanonColourControls, {
  CanonColourSolidState,
} from '#src/components/canon-colour-controls.gts';
import CanonColourSolid from '#src/components/canon-colour-solid.gts';
import CanonColourStrip from '#src/components/canon-colour-strip.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonPaletteCard from '#src/components/canon-palette-card.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonSegmented from '#src/components/canon-segmented.gts';
import CanonSplit from '#src/components/canon-split.gts';
import CanonSwitch from '#src/components/canon-switch.gts';
import CanonValueLine from '#src/components/canon-value-line.gts';
import {
  fromOklch,
  hex,
  luminance,
  oklabToLinear,
  oklch,
  parseHex,
  type Rgb,
} from '#src/lib/colour.ts';
import { solidSpaces } from '#src/lib/colour-space.ts';
import Icon from './icon.gts';
import copy from 'lucide-static/icons/copy.svg?raw';
import save from 'lucide-static/icons/download.svg?raw';
import share from 'lucide-static/icons/share.svg?raw';

// stand-in for the app's 4,926 colour names
const names: [string, Rgb][] = (
  [
    ['Black', '000000'],
    ['White', 'FFFFFF'],
    ['Grey', '808080'],
    ['Red', 'E53935'],
    ['Orange', 'FB8C00'],
    ['Yellow', 'FDD835'],
    ['Olive', '808000'],
    ['Green', '43A047'],
    ['Forest', '1E6626'],
    ['Teal', '00897B'],
    ['Cyan', '00ACC1'],
    ['Blue', '1E88E5'],
    ['Navy', '1A237E'],
    ['Purple', '8E24AA'],
    ['Pink', 'D81B60'],
    ['Brown', '6D4C41'],
    ['Cream', 'FAF5E6'],
  ] as const
).map(([name, code]) => [name, parseHex(code)!]);

function nameOf(code: string): string {
  const [r, g, b] = parseHex(code)!;
  let best = names[0]!;
  let distance = Infinity;
  for (const entry of names) {
    const [x, y, z] = entry[1];
    const d = (r - x) ** 2 + (g - y) ** 2 + (b - z) ** 2;
    if (d < distance) [best, distance] = [entry, d];
  }
  return best[0];
}

const closestName = (colour: Rgb) => nameOf(hex(colour));

function maxChroma(l: number, h: number): number {
  const radians = (h * Math.PI) / 180;
  let [low, high] = [0, 0.5];
  for (let i = 0; i < 24; i++) {
    const mid = (low + high) / 2;
    const inside = oklabToLinear(
      l,
      mid * Math.cos(radians),
      mid * Math.sin(radians),
    ).every((v) => v >= -1e-5 && v <= 1 + 1e-5);
    if (inside) low = mid;
    else high = mid;
  }
  return low;
}

function inGamut(l: number, c: number, h: number): Rgb {
  const hue = ((h % 360) + 360) % 360;
  return fromOklch(l, Math.min(c, maxChroma(l, hue)), hue);
}

const views = ['Slice', 'Ortho', 'Cut'];
const harmonyKinds = ['Analogous', 'Split'];
const normal = [
  [1, 0, 0],
  [0, 1, 0],
  [0, 0, 1],
];
const deuteranopia = [
  [0.625, 0.375, 0],
  [0.7, 0.3, 0],
  [0, 0.3, 0.7],
];

// ?colourSpace=<picker index>&colourRow=<0-3>&colourView=<0-2>: the starting state, as the iOS launch arguments
const query = new URLSearchParams(window.location.search);
const number = (key: string) => Number(query.get(key) ?? 0) || 0;
const startView = number('colourView');

/** The port of CanonColourGalleryViewController: the solid, colour cards and palette cards, driven by one colour. */
export default class ColourPage extends Component {
  state = Object.assign(
    new CanonColourSolidState({
      space: query.has('colourSpace')
        ? solidSpaces[number('colourSpace')]
        : 'hsl',
      activeRow: number('colourRow'),
    }),
    { slices: startView !== 2, viewPlane: startView === 1 },
  );
  @tracked view = startView;
  @tracked split = false;
  @tracked stripPalette = false;
  @tracked deuteranopia = false;

  get colour() {
    return this.state.colour;
  }

  get harmony(): Rgb[] {
    const [l, c, h] = oklch(this.colour);
    return (this.split ? [0, 150, 210] : [0, 30, -30]).map((turn) =>
      inGamut(l, c, h + turn),
    );
  }

  get marks() {
    return this.harmony.slice(1);
  }

  get shades(): Rgb[] {
    const [, c, h] = oklch(this.colour);
    return Array.from({ length: 9 }, (_, i) => inGamut(0.95 - i * 0.085, c, h));
  }

  get decimal() {
    return `rgb(${this.colour.map((v) => v.toFixed(4)).join(', ')})`;
  }

  get luminance() {
    return luminance(this.colour).toFixed(3);
  }

  get palette() {
    return this.stripPalette ? this.harmony : undefined;
  }

  get vision() {
    return this.deuteranopia ? deuteranopia : normal;
  }

  showView = (index: number) => {
    this.view = index;
    this.state.slices = index !== 2;
    this.state.viewPlane = index === 1;
  };

  pickHarmony = (index: number) => (this.split = index === 1);
  showStripPalette = (on: boolean) => (this.stripPalette = on);
  showDeuteranopia = (on: boolean) => (this.deuteranopia = on);

  copyPalette = () =>
    void navigator.clipboard?.writeText(this.harmony.map(hex).join('\n'));

  <template>
    <CanonSplit class="gallery" @collapsesTo={{240}}>
      <:banner>
        <CanonCanvas
          @aspect={{1}}
          @maxHeight={{640}}
          @background="var(--canon-muted)"
        >
          <div class="gallery-solid">
            <CanonColourSolid
              class="gallery-solid-picture"
              @space={{this.state.space}}
              @point={{this.state.point}}
              @animated={{this.state.animated}}
              @sliceAxis={{this.state.sliceAxis}}
              @isOrtho={{this.state.isOrtho}}
              @showsWhole={{this.state.showsWhole}}
              @marks={{this.marks}}
              @vision={{this.vision}}
              @onChange={{this.state.pick}}
              @closestName={{closestName}}
            />
            <CanonColourStrip
              @colour={{this.colour}}
              @palette={{this.palette}}
              @nameOf={{nameOf}}
            />
          </div>
        </CanonCanvas>
      </:banner>
      <:sidebar>
        <CanonRows @framed={{true}}>
          <CanonHeading @text="Solid" />
          <CanonColourControls @state={{this.state}} />
          <CanonRow @title="View" @form="flush">
            <CanonSegmented
              @items={{views}}
              @selected={{this.view}}
              @onChange={{this.showView}}
            />
          </CanonRow>
          <CanonRow @title="Strip palette" as |titleId|>
            <CanonSwitch
              @on={{this.stripPalette}}
              @onChange={{this.showStripPalette}}
              aria-labelledby={{titleId}}
            />
          </CanonRow>
          <CanonRow @title="Deuteranopia" as |titleId|>
            <CanonSwitch
              @on={{this.deuteranopia}}
              @onChange={{this.showDeuteranopia}}
              aria-labelledby={{titleId}}
            />
          </CanonRow>
        </CanonRows>
      </:sidebar>
      <:main>
        <CanonColourCard @colour={{this.colour}} @nameOf={{nameOf}} />
        <CanonColourCard
          @colour={{this.colour}}
          @layout="row"
          @nameOf={{nameOf}}
        />
        <CanonRows @framed={{true}}>
          <CanonHeading @text="Value lines" />
          <CanonValueLine
            @label="Decimal RGB"
            @value={{this.decimal}}
            @labelWidth={{92}}
          />
          <CanonValueLine
            @label="Luminance"
            @value={{this.luminance}}
            @labelWidth={{92}}
          />
        </CanonRows>
        <CanonPaletteCard
          @title="Harmony"
          @colours={{this.harmony}}
          @nameOf={{nameOf}}
        >
          <:picker>
            <CanonSegmented
              @items={{harmonyKinds}}
              @selected={{if this.split 1 0}}
              @onChange={{this.pickHarmony}}
            />
          </:picker>
          <:actions>
            <CanonButton
              @text="Copy"
              @icon={{component Icon svg=copy}}
              @kind="cell"
              @flashesCopied={{true}}
              @onClick={{this.copyPalette}}
            />
            <CanonButton
              @text="Export"
              @icon={{component Icon svg=share}}
              @kind="cell"
            />
            <CanonButton
              @text="Save"
              @icon={{component Icon svg=save}}
              @kind="cell"
            />
          </:actions>
        </CanonPaletteCard>
        <CanonPaletteCard
          @title="Shades"
          @colours={{this.shades}}
          @height={{120}}
          @nameOf={{nameOf}}
        />
      </:main>
    </CanonSplit>
  </template>
}
