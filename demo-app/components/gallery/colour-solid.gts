import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import CanonButton from '#src/components/canon-button.gts';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonColourSolid from '#src/components/canon-colour-solid.gts';
import CanonGrid from '#src/components/canon-grid.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonSegmented from '#src/components/canon-segmented.gts';
import {
  channels,
  colourAt,
  convertPoint,
  hex,
  pointFor,
  spaceNames,
  spaces,
  type Rgb,
  type Space,
} from '#src/lib/colour-solid/space.ts';
import type { Vec4 } from '#src/lib/colour-solid/vec.ts';

export const pane = 'main';
export const order = 30;

const views = ['Slice', 'Ortho', 'Cut'];
const visions: [string, number[][]][] = [
  [
    'Normal',
    [
      [1, 0, 0],
      [0, 1, 0],
      [0, 0, 1],
    ],
  ],
  [
    'Deuteranopia',
    [
      [0.625, 0.375, 0],
      [0.7, 0.3, 0],
      [0, 0.3, 0.7],
    ],
  ],
  [
    'Tritanopia',
    [
      [0.95, 0.05, 0],
      [0, 0.433, 0.567],
      [0, 0.475, 0.525],
    ],
  ],
  [
    'Achromatopsia',
    [
      [0.299, 0.587, 0.114],
      [0.299, 0.587, 0.114],
      [0.299, 0.587, 0.114],
    ],
  ],
];
const visionNames = visions.map(([name]) => name);
const markModes = ['None', 'Analogous'];
const wholeModes = ['Slice', 'Whole'];

// ?solidSpace=cmyk&solidRow=1&solidView=1&solidVision=1&solidMarks&solidWhole: the starting state, for screenshots
const query = new URLSearchParams(window.location.search);
const number = (key: string) => Number(query.get(key) ?? 0) || 0;

/** Stand-in for harmony-genny: the hue a twelfth of a turn either way, in HSL. */
function analogous(colour: Rgb): Rgb[] {
  const [h, l, s] = pointFor('hsl', colour);
  return [-1 / 12, 1 / 12].map((turn) =>
    colourAt('hsl', [h + turn + 1, l, s, 0]),
  );
}

export default class ColourSolidGallery extends Component {
  @tracked space: Space =
    spaces.find((s) => s === query.get('solidSpace')) ?? 'hsl';
  @tracked point: Vec4 = pointFor(this.space, { r: 0.12, g: 0.4, b: 0.15 });
  @tracked animated = false;
  @tracked row = number('solidRow');
  @tracked view = number('solidView');
  @tracked vision = number('solidVision');
  @tracked marksOn = query.has('solidMarks');
  @tracked whole = query.has('solidWhole');

  get spaceIndex() {
    return spaces.indexOf(this.space);
  }

  get spaceItems() {
    return spaces.map((s) => spaceNames[s]);
  }

  /** CMYK's black never slices. */
  get rowItems() {
    return channels(this.space)
      .slice(0, 3)
      .map((c) => c.name);
  }

  get sliceAxis() {
    return this.view === 2
      ? null
      : channels(this.space)[Math.min(this.row, 2)]!.axis;
  }

  get isOrtho() {
    return this.view === 1;
  }

  get visionMatrix() {
    return visions[this.vision]![1];
  }

  get colour() {
    return colourAt(this.space, this.point);
  }

  get hex() {
    return hex(this.colour);
  }

  get marks() {
    return this.marksOn ? analogous(this.colour) : [];
  }

  get isCMYK() {
    return this.space === 'cmyk';
  }

  picked = (point: Vec4) => {
    this.animated = false;
    this.point = point;
  };

  pickSpace = (index: number) => {
    const next = spaces[index]!;
    this.point = convertPoint(this.space, next, this.point);
    this.space = next;
  };

  pickRow = (index: number) => (this.row = index);
  pickView = (index: number) => (this.view = index);
  pickVision = (index: number) => (this.vision = index);
  pickMarks = (index: number) => (this.marksOn = index === 1);
  pickWhole = (index: number) => (this.whole = index === 1);

  turnHue = () => {
    const axis = channels(this.space).find((c) => c.name === 'Hue')?.axis ?? 0;
    const next = [...this.point] as Vec4;
    next[axis] = (next[axis]! + 0.25) % 1;
    this.animated = true;
    this.point = next;
  };

  /** A step of black, shown whole while it changes, as a drag on the black slider. */
  black = (step: number) => {
    const next = [...this.point] as Vec4;
    next[3] = Math.min(1, Math.max(0, next[3] + step));
    this.animated = true;
    this.whole = true;
    this.point = next;
    window.setTimeout(() => (this.whole = query.has('solidWhole')), 700);
  };

  darker = () => this.black(0.2);
  lighter = () => this.black(-0.2);

  <template>
    <CanonCanvas
      @aspect={{1}}
      @maxHeight={{520}}
      @background="var(--canon-muted)"
    >
      <CanonColourSolid
        class="gallery-solid"
        @space={{this.space}}
        @point={{this.point}}
        @animated={{this.animated}}
        @sliceAxis={{this.sliceAxis}}
        @isOrtho={{this.isOrtho}}
        @showsWhole={{this.whole}}
        @marks={{this.marks}}
        @vision={{this.visionMatrix}}
        @onChange={{this.picked}}
      />
    </CanonCanvas>
    <CanonRows @framed={{true}}>
      <CanonHeading @text="Colour solid" />
      <CanonRow @title="Pick" @detail={{this.hex}} />
      <CanonRow @title="Space" @form="stacked">
        <CanonSegmented
          @items={{this.spaceItems}}
          @selected={{this.spaceIndex}}
          @columns={{4}}
          @onChange={{this.pickSpace}}
        />
      </CanonRow>
      <CanonRow @title="Slice" @form="stacked">
        <CanonSegmented
          @items={{this.rowItems}}
          @selected={{this.row}}
          @onChange={{this.pickRow}}
        />
      </CanonRow>
      <CanonRow @title="View" @form="flush">
        <CanonSegmented
          @items={{views}}
          @selected={{this.view}}
          @onChange={{this.pickView}}
        />
      </CanonRow>
      <CanonRow @title="Vision" @form="stacked">
        <CanonSegmented
          @items={{visionNames}}
          @selected={{this.vision}}
          @columns={{2}}
          @onChange={{this.pickVision}}
        />
      </CanonRow>
      <CanonRow @title="Marks" @form="flush">
        <CanonSegmented
          @items={{markModes}}
          @selected={{if this.marksOn 1 0}}
          @onChange={{this.pickMarks}}
        />
      </CanonRow>
      <CanonRow @title="Solid" @form="flush">
        <CanonSegmented
          @items={{wholeModes}}
          @selected={{if this.whole 1 0}}
          @onChange={{this.pickWhole}}
        />
      </CanonRow>
      <CanonGrid>
        <CanonButton @text="Hue +90°" @onClick={{this.turnHue}} />
        <CanonButton
          @text="Black −"
          @disabled={{if this.isCMYK false true}}
          @onClick={{this.lighter}}
        />
        <CanonButton
          @text="Black +"
          @disabled={{if this.isCMYK false true}}
          @onClick={{this.darker}}
        />
      </CanonGrid>
    </CanonRows>
  </template>
}
