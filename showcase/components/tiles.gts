import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import type { TOC } from '@ember/component/template-only';
import { array, fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { htmlSafe } from '@ember/template';
import type { ComponentLike } from '@glint/template';
import { modifier } from 'ember-modifier';
import CanonBar from '#src/components/canon-bar.gts';
import CanonBigNumberField from '#src/components/canon-big-number-field.gts';
import CanonButton from '#src/components/canon-button.gts';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonCodeBlock from '#src/components/canon-code-block.gts';
import CanonColourCard from '#src/components/canon-colour-card.gts';
import CanonColourControls, {
  CanonColourSolidState,
} from '#src/components/canon-colour-controls.gts';
import CanonColourNotationInput from '#src/components/canon-colour-notation-input.gts';
import CanonColourSolid from '#src/components/canon-colour-solid.gts';
import CanonColourStrip from '#src/components/canon-colour-strip.gts';
import CanonColourWell from '#src/components/canon-colour-well.gts';
import CanonCommand, {
  type CanonCommandItem,
} from '#src/components/canon-command.gts';
import CanonContextMenu from '#src/components/canon-context-menu.gts';
import CanonDecimalField from '#src/components/canon-decimal-field.gts';
import CanonDetentWheel from '#src/components/canon-detent-wheel.gts';
import CanonDetentWheelRow from '#src/components/canon-detent-wheel-row.gts';
import CanonDialog, {
  type CanonDialogClose,
} from '#src/components/canon-dialog.gts';
import CanonDropZone from '#src/components/canon-drop-zone.gts';
import CanonDualList, {
  type CanonDualItem,
} from '#src/components/canon-dual-list.gts';
import CanonEmptyRow from '#src/components/canon-empty-row.gts';
import CanonFigure from '#src/components/canon-figure.gts';
import CanonFileCell from '#src/components/canon-file-cell.gts';
import CanonFromTo from '#src/components/canon-from-to.gts';
import CanonGlyphFlow from '#src/components/canon-glyph-flow.gts';
import CanonGrid from '#src/components/canon-grid.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonIcon from '#src/components/canon-icon.gts';
import CanonImageCompare from '#src/components/canon-image-compare.gts';
import CanonLamps, { type CanonLamp } from '#src/components/canon-lamps.gts';
import CanonLoader from '#src/components/canon-loader.gts';
import CanonLoupe from '#src/components/canon-loupe.gts';
import CanonMathEditor from '#src/components/canon-math-editor.gts';
import CanonMathField, {
  CanonMathFieldHandle,
} from '#src/components/canon-math-field.gts';
import CanonMathInput from '#src/components/canon-math-input.gts';
import CanonMathKey from '#src/components/canon-math-key.gts';
import CanonMathKeypad from '#src/components/canon-math-keypad.gts';
import CanonMathRail from '#src/components/canon-math-rail.gts';
import CanonMathTabs from '#src/components/canon-math-tabs.gts';
import CanonMathView from '#src/components/canon-math-view.gts';
import CanonMenu, {
  type CanonMenuEntry,
  type CanonMenuItem,
} from '#src/components/canon-menu.gts';
import CanonMenuBar, {
  type CanonMenuBarMenu,
} from '#src/components/canon-menu-bar.gts';
import CanonMenuCell from '#src/components/canon-menu-cell.gts';
import CanonNumberField from '#src/components/canon-number-field.gts';
import CanonPage from '#src/components/canon-page.gts';
import CanonPageStrip, {
  pageStripHeight,
  type CanonPage as CanonPageItem,
} from '#src/components/canon-page-strip.gts';
import CanonPaletteCard from '#src/components/canon-palette-card.gts';
import CanonPopover from '#src/components/canon-popover.gts';
import CanonPreviewPanel from '#src/components/canon-preview-panel.gts';
import CanonReadoutBand from '#src/components/canon-readout-band.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonRule from '#src/components/canon-rule.gts';
import CanonSegmented from '#src/components/canon-segmented.gts';
import CanonSheet, {
  type CanonSheetEdge,
} from '#src/components/canon-sheet.gts';
import CanonSidebar from '#src/components/canon-sidebar.gts';
import CanonSidebarRow, {
  type CanonSidebarLight,
} from '#src/components/canon-sidebar-row.gts';
import CanonSlider from '#src/components/canon-slider.gts';
import CanonSplit from '#src/components/canon-split.gts';
import CanonStatus from '#src/components/canon-status.gts';
import CanonStepper from '#src/components/canon-stepper.gts';
import CanonSwatch from '#src/components/canon-swatch.gts';
import CanonSwitch from '#src/components/canon-switch.gts';
import CanonTextArea from '#src/components/canon-text-area.gts';
import CanonTextCell from '#src/components/canon-text-cell.gts';
import CanonTextInput from '#src/components/canon-text-input.gts';
import CanonTextOutput from '#src/components/canon-text-output.gts';
import CanonTiles from '#src/components/canon-tiles.gts';
import CanonTimecode from '#src/components/canon-timecode.gts';
import CanonTooltip from '#src/components/canon-tooltip.gts';
import CanonValueLine from '#src/components/canon-value-line.gts';
import CanonWindow from '#src/components/canon-window.gts';
import { hex, parseHex, type Rgb } from '#src/lib/colour.ts';
import { solidSpaces, spaceNames } from '#src/lib/colour-space.ts';
import type { GlyphKind } from '#src/lib/glyph-rows.ts';
import { frame } from '#src/lib/loupe.ts';
import type { CanonPlacement } from '#src/lib/popover.ts';
import { MathEditing } from '#src/lib/math/editing.ts';
import { Expression, type Key } from '#src/lib/math/expression.ts';
import type CanonToastService from '#src/services/canon-toast.ts';
import GalleryArt from '../../demo-app/components/gallery-art.gts';
import Icon from '../../demo-app/components/icon.gts';
import aperture from 'lucide-static/icons/aperture.svg?raw';
import blend from 'lucide-static/icons/blend.svg?raw';
import bug from 'lucide-static/icons/bug.svg?raw';
import camera from 'lucide-static/icons/camera.svg?raw';
import caseSensitive from 'lucide-static/icons/case-sensitive.svg?raw';
import chevronDown from 'lucide-static/icons/chevron-down.svg?raw';
import circleDot from 'lucide-static/icons/circle-dot.svg?raw';
import clipboard from 'lucide-static/icons/clipboard.svg?raw';
import clipboardPaste from 'lucide-static/icons/clipboard-paste.svg?raw';
import commandKey from 'lucide-static/icons/command.svg?raw';
import contrast from 'lucide-static/icons/contrast.svg?raw';
import copy from 'lucide-static/icons/copy.svg?raw';
import file from 'lucide-static/icons/file.svg?raw';
import hashSvg from 'lucide-static/icons/hash.svg?raw';
import keyboard from 'lucide-static/icons/keyboard.svg?raw';
import messageSquareCheck from 'lucide-static/icons/message-square-check.svg?raw';
import moveHorizontal from 'lucide-static/icons/move-horizontal.svg?raw';
import palette from 'lucide-static/icons/palette.svg?raw';
import panelBottom from 'lucide-static/icons/panel-bottom.svg?raw';
import panelLeft from 'lucide-static/icons/panel-left.svg?raw';
import panelRight from 'lucide-static/icons/panel-right.svg?raw';
import panelTop from 'lucide-static/icons/panel-top.svg?raw';
import pencil from 'lucide-static/icons/pencil.svg?raw';
import play from 'lucide-static/icons/play.svg?raw';
import repeat from 'lucide-static/icons/repeat.svg?raw';
import rotateCw from 'lucide-static/icons/rotate-cw.svg?raw';
import ruler from 'lucide-static/icons/ruler.svg?raw';
import settings from 'lucide-static/icons/settings.svg?raw';
import share from 'lucide-static/icons/share.svg?raw';
import square from 'lucide-static/icons/square.svg?raw';
import textSvg from 'lucide-static/icons/text.svg?raw';
import trash from 'lucide-static/icons/trash-2.svg?raw';
import wrench from 'lucide-static/icons/wrench.svg?raw';
import zoomIn from 'lucide-static/icons/zoom-in.svg?raw';
import zoomOut from 'lucide-static/icons/zoom-out.svg?raw';

// ∑CG: showcase, prompt inside the drop zone tile
//   spec: invites dropping a file onto the area; four to six words, sentence case, no period
//   sample: "Drop an image here"
const dropPrompt = '∑CG';

// ∑CG: showcase, the message of the export dialog under its title
//   spec: one sentence saying the palette is saved as a file in the chosen format; up to 90 chars, plain, sentence case
//   sample: "The palette is saved as one file in the format you pick."
const exportMessage = '∑CG';

// ∑CG: showcase, the message of the delete alert under its title
//   spec: one sentence warning that deleting the palette cannot be undone; up to 70 chars, plain, sentence case
//   sample: "This palette and its swatches go for good."
const deleteMessage = '∑CG';

const hexes = (codes: string[]): Rgb[] => codes.map((code) => parseHex(code)!);
const forest: Rgb = [0.118, 0.4, 0.149];
const harmony = hexes(['1E6626', '2E7D6B', '4F6B1E']);
const shades = hexes([
  'E8F3E6',
  'C4E0BF',
  '93C68B',
  '5FA656',
  '3A8535',
  '1E6626',
  '154A1B',
  '0C3011',
  '051A08',
]);
const rates = ['23.976', '24', '25'];
const modes = ['Region', 'Window', 'Screen', 'Timed'];
const sizes = ['Tiny', 'Base', 'Small', 'Large'];
const switches = ['Images', 'Files'];
const longestSwitch = 'Images';
const icons = [bug, rotateCw, copy, share, zoomIn, circleDot];
const playLoop: CanonLamp[] = ['play', 'loop'];
const recordPause: CanonLamp[] = ['record', 'pause'];
const record: CanonLamp[] = ['record'];
const over = { playhead: 83.4, playing: true, looping: true };
const whole = (value: number) => String(Math.round(value));
const smpte = () => '01:02:03:04';
const spaceName = (index: number) => spaceNames[solidSpaces[index]!];
const isEven = (index: number) => index % 2 === 0;
const code = `.button {
    border-radius: 0;
    color: oklch(0.45 0.12 145);
}`;
const audio = [
  { label: 'Codec', value: 'AAC' },
  { label: 'Sample rate', value: '44100 Hz' },
  { label: 'Peak', value: '-4.3 dBFS', level: 0.93 },
  { label: 'RMS', value: '-13.6 dBFS', level: 0.77 },
];
const fill = htmlSafe('block-size: 100%');

function hsv(h: number, s: number, v: number) {
  const f = (n: number) => {
    const k = (n + h * 6) % 6;
    return Math.round(255 * (v - v * s * Math.max(0, Math.min(k, 4 - k, 1))));
  };
  return `rgb(${f(5)},${f(3)},${f(1)})`;
}

function bands(saturation: number) {
  const rects = Array.from(
    { length: 32 },
    (_, x) =>
      `<rect x="${x * 10}" width="10" height="160" shape-rendering="crispEdges" fill="${hsv(x / 32, saturation, 0.9)}"/>`,
  ).join('');
  return `data:image/svg+xml,${encodeURIComponent(
    `<svg xmlns="http://www.w3.org/2000/svg" width="320" height="160">${rects}</svg>`,
  )}`;
}

const before = bands(0.8);
const after = bands(0);

// the colour's shades around the middle pixel, as the iOS gallery draws them
function loupePixels(colour: Rgb): ImageData {
  const side = 15;
  const pixels = new ImageData(side, side);
  for (let y = 0; y < side; y++) {
    for (let x = 0; x < side; x++) {
      const toward = (x + y) % 2 === 0 ? 1 : 0;
      const by = (Math.abs(x - 7) + Math.abs(y - 7)) / 16;
      const at = (y * side + x) * 4;
      colour.forEach((channel, i) => {
        pixels.data[at + i] = Math.round(
          (channel + (toward - channel) * by) * 255,
        );
      });
      pixels.data[at + 3] = 255;
    }
  }
  return pixels;
}

const loupe = loupePixels(forest);

const placeLoupe = modifier((element: HTMLElement) => {
  const box = element.parentElement!;
  const observer = new ResizeObserver(() => {
    const { clientWidth: width, clientHeight: height } = box;
    const spot = frame(
      { x: width / 2, y: height / 2 },
      112,
      24,
      { width, height },
      8,
    );
    element.style.insetInlineStart = `${spot.x}px`;
    element.style.insetBlockStart = `${spot.y}px`;
  });
  observer.observe(box);
  return () => observer.disconnect();
});

const Bar = <template>
  <CanonRow @title="Plain"><CanonBar
      class="gallery-bar"
      @share={{0.65}}
    /></CanonRow>
  <CanonRow @title="Low"><CanonBar
      class="gallery-bar"
      @share={{0.3}}
    /></CanonRow>
</template>;

class BigNumber extends Component {
  @tracked big = '16';

  setBig = (text: string) => (this.big = text);
  stepBig = (direction: -1 | 1) =>
    (this.big = String(Math.max(0, (parseInt(this.big) || 0) + direction)));

  <template>
    <CanonBigNumberField
      @value={{this.big}}
      @placeholder="0"
      @unit="PX"
      @label="Big number"
      @onStep={{this.stepBig}}
      @onInput={{this.setBig}}
    />
  </template>
}

const Buttons = <template>
  <CanonButton
    @text="Generate"
    @icon={{component Icon svg=rotateCw}}
    @kind="primary"
  />
  <CanonGrid>
    <CanonButton @text="Copy" @icon={{component Icon svg=copy}} />
    <CanonButton
      @text="Export"
      @icon={{component Icon svg=share}}
      @kind="primary"
    />
  </CanonGrid>
  <CanonButton
    @text="Copy"
    @icon={{component Icon svg=copy}}
    @flashesCopied={{true}}
  />
</template>;

class Canvas extends Component {
  @tracked lines = 1;

  get text() {
    return Array.from({ length: this.lines }, (_, i) => `Line ${i + 1}`);
  }

  more = () => (this.lines = (this.lines % 4) + 1);

  <template>
    <CanonCanvas @aspect={{4}}><GalleryArt
        @label="Column canvas"
      /></CanonCanvas>
    <CanonCanvas @fitting={{true}} @animated={{true}}>
      <button type="button" class="gallery-fit" {{on "click" this.more}}>
        {{#each this.text as |line|}}<span>{{line}}</span>{{/each}}
      </button>
    </CanonCanvas>
  </template>
}

const CodeBlock = <template>
  <CanonCodeBlock @code={{code}} @language="css" />
</template>;

const ColourCard = <template>
  <CanonColourCard @colour={{forest}} />
  <CanonColourCard @colour={{forest}} @layout="row" />
</template>;

class ColourControls extends Component {
  state = new CanonColourSolidState({ space: 'hsl' });

  <template><CanonColourControls @state={{this.state}} /></template>
}

class ColourNotation extends Component {
  @tracked colour = forest;

  use = (colour: Rgb) => (this.colour = colour);

  <template>
    <CanonRow @title="Any notation" @form="stacked" as |titleId|>
      <CanonColourNotationInput
        @colour={{this.colour}}
        @onColour={{this.use}}
        @labelledBy={{titleId}}
      />
    </CanonRow>
  </template>
}

class ColourSolid extends Component {
  state = new CanonColourSolidState({ space: 'hsl' });

  <template>
    <CanonCanvas @aspect={{1}} @background="var(--canon-muted)">
      <CanonColourSolid
        @space={{this.state.space}}
        @point={{this.state.point}}
        @animated={{this.state.animated}}
        @sliceAxis={{this.state.sliceAxis}}
        @isOrtho={{this.state.isOrtho}}
        @showsWhole={{this.state.showsWhole}}
        @onChange={{this.state.pick}}
      />
    </CanonCanvas>
  </template>
}

const ColourStrip = <template>
  <CanonColourStrip @colour={{forest}} @palette={{harmony}} />
</template>;

class ColourWells extends Component {
  @tracked foreground: Rgb = forest;
  @tracked orange: Rgb = [1, 0.584, 0];

  setForeground = (colour: Rgb) => (this.foreground = colour);
  setOrange = (colour: Rgb) => (this.orange = colour);

  <template>
    <CanonColourWell
      @label="Foreground"
      @colour={{this.foreground}}
      @format="oklch"
      @onChange={{this.setForeground}}
    />
    <CanonColourWell @colour={{this.orange}} @onChange={{this.setOrange}} />
  </template>
}

class DecimalField extends Component {
  @tracked seconds = 1.5;

  setSeconds = (value: number) => (this.seconds = value);

  <template>
    <CanonRow @title="Decimal" @form="flush" as |titleId|>
      <CanonDecimalField
        @value={{this.seconds}}
        @labelledBy={{titleId}}
        @onChange={{this.setSeconds}}
      />
    </CanonRow>
  </template>
}

class DetentWheel extends Component {
  @tracked selected = 0;

  select = (index: number) => (this.selected = index);

  <template>
    <CanonCanvas @height={{200}}>
      <CanonDetentWheel
        @count={{solidSpaces.length}}
        @selected={{this.selected}}
        @onSelect={{this.select}}
        @text={{spaceName}}
        @label="Space"
        as |index focus|
      >
        <CanonDetentWheelRow @focus={{focus}}>{{spaceName
            index
          }}</CanonDetentWheelRow>
      </CanonDetentWheel>
    </CanonCanvas>
  </template>
}

const DetentWheelRows = <template>
  <div class="showcase-wheel-rows">
    <CanonDetentWheelRow @focus={{0}}>HSV</CanonDetentWheelRow>
    <CanonDetentWheelRow @focus={{1}}>HSL</CanonDetentWheelRow>
    <CanonDetentWheelRow @focus={{0.3}}>OKLCH</CanonDetentWheelRow>
  </div>
</template>;

const DropZone = <template>
  <CanonDropZone
    @prompt={{dropPrompt}}
    @icon={{component Icon svg=file}}
    @accept=""
    @multiple={{true}}
    @paste={{false}}
  />
</template>;

class DualList extends Component {
  @tracked hidden: CanonDualItem[] = [
    { id: 'b', name: 'Beta', caption: 'two' },
    { id: 'd', name: 'Delta', caption: 'four' },
  ];
  @tracked shown: CanonDualItem[] = [
    { id: 'a', name: 'Alpha', caption: 'one' },
    { id: 'c', name: 'Gamma', caption: 'three' },
  ];

  moveRight = (id: string) => {
    const item = this.hidden.find((i) => i.id === id);
    if (!item) return;
    this.hidden = this.hidden.filter((i) => i !== item);
    this.shown = [...this.shown, item];
  };

  moveLeft = (id: string) => {
    const item = this.shown.find((i) => i.id === id);
    if (!item) return;
    this.shown = this.shown.filter((i) => i !== item);
    this.hidden = [...this.hidden, item];
  };

  reorder = (id: string, delta: -1 | 1) => {
    const index = this.shown.findIndex((i) => i.id === id);
    const other = index + delta;
    if (index < 0 || other < 0 || other >= this.shown.length) return;
    const next = [...this.shown];
    [next[index], next[other]] = [next[other]!, next[index]!];
    this.shown = next;
  };

  <template>
    <CanonDualList
      @left={{this.hidden}}
      @right={{this.shown}}
      @leftTitle="Hidden"
      @rightTitle="Shown"
      @listHeight={{140}}
      @onMoveRight={{this.moveRight}}
      @onMoveLeft={{this.moveLeft}}
      @onReorder={{this.reorder}}
    />
  </template>
}

const EmptyRow = <template><CanonEmptyRow @text="Nothing here" /></template>;

class NumberField extends Component<{ Args: { figure?: boolean } }> {
  @tracked number = 200;

  get figure() {
    return String(this.number);
  }

  setNumber = (value: number) => (this.number = value);

  <template>
    <CanonRow @title="Number" @form="flush" as |titleId|>
      <CanonNumberField
        @value={{this.number}}
        @max={{5000}}
        @step={{50}}
        @unit="items"
        @labelledBy={{titleId}}
        @onChange={{this.setNumber}}
      />
    </CanonRow>
    {{#if @figure}}
      <CanonRow @title="Figure" @detail="Follows Number">
        <CanonFigure @text={{this.figure}} @unit="px" @size={{28}} />
      </CanonRow>
    {{/if}}
  </template>
}

const Figure = <template><NumberField @figure={{true}} /></template>;

const FileCell = <template>
  <CanonRow @title="File" @form="flush" as |titleId|>
    <CanonFileCell @labelledBy={{titleId}} />
  </CanonRow>
  <CanonRow @title="Image" @form="flush" as |titleId|>
    <CanonFileCell @accept="image/*" @labelledBy={{titleId}} />
  </CanonRow>
</template>;

const FromTo = <template>
  <CanonFromTo @items={{rates}} @from={{0}} @to={{2}} />
</template>;

const metrics = { height: 36, rowGap: 8, gap: 4 };
const measure = () => 28;
const kind = (c: string): GlyphKind =>
  c === '\n' ? 'newline' : /\s/.test(c) ? 'space' : 'glyph';
const isSpace = (c: string) => /\s/.test(c);
const glyphStart = 'Glyph flow';

class GlyphFlow extends Component {
  @tracked text = glyphStart;

  get glyphs() {
    return [...this.text];
  }

  change = (text: string) => (this.text = text);

  <template>
    <CanonCanvas @height={{120}}>
      <CanonGlyphFlow
        @glyphs={{this.glyphs}}
        @metrics={{metrics}}
        @measure={{measure}}
        @kind={{kind}}
        @label={{this.text}}
        as |glyph|
      >
        {{#unless (isSpace glyph)}}
          <span class="gallery-glyph">{{glyph}}</span>
        {{/unless}}
      </CanonGlyphFlow>
    </CanonCanvas>
    <CanonTextInput @value={{glyphStart}} @onChange={{this.change}} />
  </template>
}

const Grid = <template>
  <CanonGrid>
    <CanonButton @text="Cancel" />
    <CanonButton @text="Apply" @kind="primary" />
  </CanonGrid>
  <CanonRow @title="Icon actions" @detail="3.60 – 6.00" @form="flush">
    <CanonGrid>
      <CanonButton
        @kind="cell"
        @icon={{component Icon svg=zoomOut}}
        @label="Zoom out"
      />
      <CanonButton
        @kind="cell"
        @icon={{component Icon svg=zoomIn}}
        @label="Zoom in"
      />
      <CanonButton
        @kind="cell"
        @icon={{component Icon svg=moveHorizontal}}
        @label="Fit width"
      />
    </CanonGrid>
  </CanonRow>
</template>;

const Heading = <template><CanonHeading @text="Rows" /></template>;

const Icons = <template>
  <div class="showcase-stage showcase-icons">
    {{#each icons as |svg|}}<CanonIcon @svg={{svg}} />{{/each}}
  </div>
</template>;

const ImageCompare = <template>
  <CanonCanvas @aspect={{2}} @background="var(--canon-muted)">
    <CanonImageCompare @before={{before}} @after={{after}} @afterTitle="Grey" />
  </CanonCanvas>
</template>;

const Lamps = <template>
  <div class="showcase-stage">
    <CanonLamps @lit={{playLoop}} />
    <CanonLamps @lamps={{recordPause}} @lit={{record}} />
  </div>
</template>;

const Loaders = <template>
  <div class="showcase-stage gallery-loaders">
    <CanonLoader />
    <CanonLoader @mode="comet" @reverse={{true}} />
    <CanonLoader @mode="dot" />
    <CanonLoader @mode="twin" />
    <CanonLoader @mode="thinking" />
    <CanonLoader @cell={{4}} @gap={{1}} />
  </div>
</template>;

const Loupe = <template>
  <CanonCanvas @height={{200}} @background="var(--canon-muted)">
    <CanonLoupe
      class="gallery-loupe"
      @pixels={{loupe}}
      @colour={{forest}}
      {{placeLoupe}}
    />
  </CanonCanvas>
</template>;

class MathEditor extends Component {
  editing = new MathEditing(new Expression('(x+1)^2/2'));

  <template>
    <div class="showcase-editor">
      <CanonMathEditor @editing={{this.editing}} />
    </div>
  </template>
}

const inserts: Key[] = [
  { kind: 'fraction' },
  { kind: 'power' },
  { kind: 'root' },
  { kind: 'symbol', symbol: '×' },
];

class MathField extends Component {
  handle = new CanonMathFieldHandle();

  insert = (key: Key) => this.handle.edit([key]);

  <template>
    <CanonMathField
      @text="(x+1)^2/2"
      @placeholder="x^2 - 4"
      @handle={{this.handle}}
    />
    <CanonGrid @columns={{4}}>
      {{#each inserts as |key|}}
        <CanonMathKey @key={{key}} @onClick={{fn this.insert key}} />
      {{/each}}
    </CanonGrid>
  </template>
}

class MathInput extends Component {
  @tracked open = false;
  @tracked text = 'sqrt(x^2+1)/(2*x)';

  show = () => (this.open = true);
  close = (text: string) => {
    this.text = text;
    this.open = false;
  };

  <template>
    <div class="showcase-stage">
      <CanonMathView @text={{this.text}} @size={{22}} />
    </div>
    <CanonButton @text="Open" @onClick={{this.show}} />
    {{#if this.open}}
      <CanonMathInput @text={{this.text}} @onClose={{this.close}} />
    {{/if}}
  </template>
}

const MathKeys = <template>
  <CanonGrid @columns={{4}}>
    {{#each inserts as |key|}}<CanonMathKey @key={{key}} />{{/each}}
  </CanonGrid>
</template>;

const MathKeypad = <template><CanonMathKeypad @variable="t" /></template>;

const MathRail = <template><CanonMathRail /></template>;

class MathTabs extends Component {
  @tracked page = 0;

  select = (page: number) => (this.page = page);

  <template>
    <CanonMathTabs @progress={{this.page}} @onSelect={{this.select}} />
  </template>
}

const morphs = ['(x+1)^2', 'x^2+2*x+1', '(x+1)*(x+1)'];

class MathView extends Component {
  @tracked morph = 0;

  get morphText() {
    return morphs[this.morph % morphs.length];
  }

  next = () => (this.morph += 1);

  <template>
    <div class="showcase-stage">
      <CanonMathView @text="sqrt(x^2+1)/(2*x)" @size={{22}} />
      <CanonMathView @text="sum(k^2,k,1,n)" @size={{22}} />
      <CanonMathView @text="b*c^(-1)+(1/2)*x^(-1/2)" @presents={{true}} />
    </div>
    <CanonCanvas @height={{120}}>
      <CanonMathView
        @text={{this.morphText}}
        @size={{30}}
        @morphs={{true}}
        style={{fill}}
      />
    </CanonCanvas>
    <CanonButton @text="Morph" @onClick={{this.next}} />
  </template>
}

const MenuCell = <template>
  <CanonRow @title="Menu" @form="flush" as |titleId|>
    <CanonMenuCell @items={{rates}} @selected={{0}} @labelledBy={{titleId}} />
  </CanonRow>
</template>;

const Page = <template>
  <div class="showcase-box">
    <CanonPage>
      <CanonCanvas @height={{64}}><GalleryArt @label="Page" /></CanonCanvas>
      <CanonRows @framed={{true}}>
        <CanonRow @title="Plain" />
        <CanonRow @title="Scrolls" />
        <CanonRow @title="Centred" />
      </CanonRows>
    </CanonPage>
  </div>
</template>;

class PageStrip extends Component {
  @tracked pages: CanonPageItem[] = [
    { size: { width: 595, height: 842 }, name: 'Plain' },
    { size: { width: 842, height: 595 }, name: 'Lit' },
    { size: { width: 595, height: 842 }, name: 'Depth 2', depth: 2 },
    {
      size: { width: 595, height: 842 },
      name: 'Picture',
      picture: before,
      area: { x: 40, y: 60, width: 515, height: 722 },
      placement: { x: 40, y: 262, width: 515, height: 320 },
      turn: 90,
    },
  ];
  @tracked selected = 1;

  select = (index: number) => (this.selected = index);

  move = (from: number, to: number) => {
    const pages = [...this.pages];
    pages.splice(to, 0, ...pages.splice(from, 1));
    if (this.selected === from) this.selected = to;
    this.pages = pages;
  };

  menu = (index: number) => [
    { title: 'Duplicate', action: () => this.duplicate(index) },
    { title: 'Delete', action: () => this.remove(index), destructive: true },
  ];

  duplicate(index: number) {
    const pages = [...this.pages];
    pages.splice(index + 1, 0, pages[index]!);
    this.pages = pages;
  }

  remove(index: number) {
    this.pages = this.pages.filter((_, i) => i !== index);
  }

  <template>
    <CanonCanvas @height={{pageStripHeight}} @background="var(--canon-muted)">
      <CanonPageStrip
        @pages={{this.pages}}
        @selected={{this.selected}}
        @onSelect={{this.select}}
        @reorders={{true}}
        @onMove={{this.move}}
        @menu={{this.menu}}
      />
    </CanonCanvas>
  </template>
}

class PaletteCard extends Component {
  @service('canon-toast') declare toast: CanonToastService;

  copyHarmony = () => void this.toast.copy(harmony.map(hex).join('\n'));

  <template>
    <CanonPaletteCard @title="Harmony" @colours={{harmony}}>
      <:actions>
        <CanonButton
          @text="Copy"
          @icon={{component Icon svg=copy}}
          @kind="cell"
          @onClick={{this.copyHarmony}}
        />
      </:actions>
    </CanonPaletteCard>
    <CanonPaletteCard @title="Shades" @colours={{shades}} @height={{120}} />
  </template>
}

const PreviewPanel = <template>
  <CanonPreviewPanel @caption="Preview" @detail="1600 x 900">
    <div class="gallery-swatch"></div>
  </CanonPreviewPanel>
</template>;

const ReadoutBand = <template>
  <CanonCanvas @height={{120}}>
    <CanonReadoutBand @transport={{over}}>
      <GalleryArt @label="Readout over" />
    </CanonReadoutBand>
  </CanonCanvas>
</template>;

const Row = <template>
  <CanonRow @title="Plain"><CanonBar
      class="gallery-bar"
      @share={{0.65}}
    /></CanonRow>
  <CanonRow @title="Icon" @icon={{component Icon svg=bug}}><CanonBar
      class="gallery-bar"
      @share={{0.3}}
    /></CanonRow>
  <CanonRow @title="Mode" @form="stacked">
    <CanonSegmented @items={{modes}} />
  </CanonRow>
</template>;

const Rows = <template>
  <CanonRows>
    <CanonRow @title="One" />
    <CanonRow @title="Two" />
    <CanonRow @title="Three" />
  </CanonRows>
</template>;

const Rule = <template>
  <div class="showcase-stage showcase-rules">
    <span>Left</span>
    <CanonRule @vertical={{true}} />
    <span>Right</span>
    <CanonRule class="showcase-rule-across" />
  </div>
</template>;

const Segmented = <template>
  <CanonRow @title="Mode" @form="stacked">
    <CanonSegmented @items={{modes}} />
  </CanonRow>
  <CanonSegmented
    @items={{sizes}}
    @selected={{1}}
    @disabledIndices={{array 2 3}}
  />
</template>;

const Slider = <template>
  <CanonRow @title="Slider" @form="flush" as |titleId|>
    <CanonSlider @value={{0.65}} @labelledBy={{titleId}} />
  </CanonRow>
  <CanonRow @title="Stepped slider" @form="flush" as |titleId|>
    <CanonSlider
      @value={{80}}
      @min={{1}}
      @max={{100}}
      @step={{1}}
      @readout={{whole}}
      @labelledBy={{titleId}}
    />
  </CanonRow>
</template>;

const Split = <template>
  <div class="showcase-box showcase-box--split">
    <CanonSplit>
      <:banner>
        <CanonCanvas @height={{64}}><GalleryArt
            @label="All columns"
          /></CanonCanvas>
      </:banner>
      <:sidebar>
        <CanonRows @framed={{true}}>
          <CanonHeading @text="Sidebar" />
          <CanonRow @title="Plain" />
        </CanonRows>
      </:sidebar>
      <:main>
        <CanonRows @framed={{true}}>
          <CanonHeading @text="Main" />
          <CanonRow @title="Plain" />
          <CanonRow @title="Second" />
        </CanonRows>
      </:main>
      <:footer>
        <CanonGrid>
          <CanonButton @text="Loop" @icon={{component Icon svg=repeat}} />
          <CanonButton
            @text="Play"
            @icon={{component Icon svg=play}}
            @kind="primary"
          />
          <CanonButton @text="Stop" @icon={{component Icon svg=square}} />
        </CanonGrid>
      </:footer>
    </CanonSplit>
  </div>
</template>;

const Status = <template>
  <CanonRow @title="Status">
    <div class="gallery-inline">
      <CanonStatus @text="Granted" @tone="ok" />
      <CanonStatus @text="Not granted" @tone="warn" />
      <CanonStatus @text="Stopped" @tone="muted" />
    </div>
  </CanonRow>
</template>;

class Stepper extends Component {
  @tracked count = 3;

  step = (direction: -1 | 1) => (this.count += direction);

  <template>
    <CanonStepper @onStep={{this.step}}>
      <span class="canon-stepper-value">{{this.count}}</span>
    </CanonStepper>
  </template>
}

const Swatches = <template>
  <div class="showcase-swatches">
    {{#each harmony as |colour|}}<CanonSwatch @colour={{colour}} />{{/each}}
  </div>
</template>;

const Switches = <template>
  <CanonRow @title="Switch" as |titleId|>
    <CanonSwitch @on={{true}} aria-labelledby={{titleId}} />
  </CanonRow>
  <CanonGrid>
    {{#each switches as |title index|}}
      <CanonRow @title={{title}} @sizingTitle={{longestSwitch}} as |id|>
        <CanonSwitch @on={{isEven index}} aria-labelledby={{id}} />
      </CanonRow>
    {{/each}}
  </CanonGrid>
</template>;

const TextArea = <template>
  <CanonTextArea
    @placeholder="Text area"
    @height={{120}}
    aria-label="Text area"
  />
</template>;

const TextCell = <template>
  <CanonRow @title="Text" @form="flush" as |titleId|>
    <CanonTextCell @placeholder="Trigger" aria-labelledby={{titleId}} />
  </CanonRow>
</template>;

class TextInput extends Component {
  @tracked text = glyphStart;

  change = (text: string) => (this.text = text);

  <template>
    <CanonTextInput @value={{glyphStart}} @onChange={{this.change}} />
    <CanonStatus @text={{this.text}} @tone="muted" @row={{true}} />
  </template>
}

const TextOutput = <template>
  <CanonTextOutput
    @text="GLYPH FLOW"
    @heading="Text output"
    @fileName="showcase.txt"
  />
</template>;

const Tiles = <template><CanonTiles @items={{audio}} /></template>;

const Timecodes = <template>
  <div class="showcase-stage">
    <CanonTimecode @seconds={{83.4}} />
    <CanonTimecode @seconds={{1}} @format={{smpte}} @size={{28}} />
  </div>
</template>;

class Toast extends Component {
  @service('canon-toast') declare toast: CanonToastService;

  show = () => this.toast.show('#3B82F6');

  <template>
    <CanonButton
      @text="Toast"
      @icon={{component Icon svg=messageSquareCheck}}
      @onClick={{this.show}}
    />
  </template>
}

const ValueLines = <template>
  <CanonValueLine
    @label="Decimal RGB"
    @value="rgb(0.1180, 0.4000, 0.1490)"
    @labelWidth={{92}}
  />
  <CanonValueLine @label="Above" @value="#1E6626" @layout="above" />
  <CanonValueLine
    @label="01"
    @value="#1E6626"
    @layout="numbered"
    @lit={{true}}
  />
</template>;

const eq = (a: string, b: string) => a === b;

const commandItems: CanonCommandItem[] = [
  {
    id: 'contrast',
    title: 'Contrast checker',
    group: 'Colour',
    keywords: ['wcag', 'apca'],
    icon: <template><Icon @svg={{contrast}} /></template>,
  },
  {
    id: 'shades',
    title: 'Tailwind shades',
    group: 'Colour',
    keywords: ['palette', 'scale'],
    icon: <template><Icon @svg={{palette}} /></template>,
  },
  {
    id: 'harmony',
    title: 'Harmony genny',
    group: 'Colour',
    keywords: ['complementary', 'triad'],
    icon: <template><Icon @svg={{blend}} /></template>,
  },
  {
    id: 'case',
    title: 'Case converter',
    group: 'Text',
    keywords: ['upper', 'lower', 'title'],
    icon: <template><Icon @svg={{caseSensitive}} /></template>,
  },
  {
    id: 'count',
    title: 'Word counter',
    group: 'Text',
    detail: 'Text › Analysis',
    icon: <template><Icon @svg={{textSvg}} /></template>,
  },
  {
    id: 'hash',
    title: 'Hash generator',
    group: 'Text',
    keywords: ['sha', 'md5'],
    icon: <template><Icon @svg={{hashSvg}} /></template>,
  },
  {
    id: 'copy',
    title: 'Copy',
    group: 'Actions',
    shortcut: ['⌘', 'C'],
    icon: <template><Icon @svg={{copy}} /></template>,
  },
  {
    id: 'paste',
    title: 'Paste',
    group: 'Actions',
    shortcut: ['⌘', 'V'],
    disabled: true,
    icon: <template><Icon @svg={{clipboardPaste}} /></template>,
  },
  {
    id: 'delete',
    title: 'Delete palette',
    group: 'Actions',
    shortcut: ['⌘', '⌫'],
    icon: <template><Icon @svg={{trash}} /></template>,
  },
];

const rulerIcon = <template><Icon @svg={{ruler}} /></template>;
const commandIcon = <template><Icon @svg={{commandKey}} /></template>;
const pxPer: Record<string, number> = {
  px: 1,
  pt: 96 / 72,
  mm: 96 / 25.4,
  in: 96,
};

/** The Omnibox units answer, for lengths only: "12 pt" answers in the other units. */
function answers(query: string): CanonCommandItem[] {
  const match = /^(-?\d+(?:\.\d+)?)\s*(px|pt|mm|in)$/i.exec(query.trim());
  if (!match) return [];
  const unit = match[2]!.toLowerCase();
  const px = Number(match[1]) * pxPer[unit]!;
  const title = Object.keys(pxPer)
    .filter((other) => other !== unit)
    .map((other) => `${+(px / pxPer[other]!).toFixed(2)} ${other}`)
    .join(' · ');
  return [
    {
      id: 'answer',
      title,
      detail: query.trim(),
      answer: true,
      icon: rulerIcon,
    },
  ];
}

const paletteStyle = htmlSafe('--canon-dialog-width: 640px');

class Command extends Component {
  @tracked query = '';
  @tracked paletteQuery = '';
  @tracked picked = '';
  @tracked open = false;

  get items() {
    return [...answers(this.query), ...commandItems];
  }

  get paletteItems() {
    return [...answers(this.paletteQuery), ...commandItems];
  }

  setQuery = (query: string) => (this.query = query);
  setPaletteQuery = (query: string) => (this.paletteQuery = query);
  select = (item: CanonCommandItem) => (this.picked = item.title);
  run = (close: CanonDialogClose, item: CanonCommandItem) => {
    this.picked = item.title;
    close(item.id);
  };
  show = () => (this.open = true);
  close = () => {
    this.open = false;
    this.paletteQuery = '';
  };

  <template>
    <CanonCommand
      @items={{this.items}}
      @placeholder="Search tools"
      @onSelect={{this.select}}
      @onQuery={{this.setQuery}}
    />
    <CanonRow @title="Picked" @detail={{if this.picked this.picked "—"}} />
    <CanonRow @title="Palette" @form="flush">
      <CanonButton
        @kind="cell"
        @text="Open"
        @icon={{commandIcon}}
        @onClick={{this.show}}
      />
    </CanonRow>
    <CanonDialog
      @open={{this.open}}
      @onClose={{this.close}}
      aria-label="Command palette"
      style={{paletteStyle}}
    >
      <:default as |close|>
        <CanonCommand
          @items={{this.paletteItems}}
          @placeholder="Search tools"
          @onSelect={{fn this.run close}}
          @onQuery={{this.setPaletteQuery}}
        />
      </:default>
    </CanonDialog>
  </template>
}

const formats = ['ASE', 'GPL', 'JSON'];
const units = ['px', 'pt', 'mm'];

class Dialog extends Component {
  @tracked dialog = false;
  @tracked alert = false;
  @tracked returned = '';

  openDialog = () => (this.dialog = true);
  openAlert = () => (this.alert = true);
  closeDialog = (value: string) => {
    this.dialog = false;
    this.returned = value;
  };
  closeAlert = (value: string) => {
    this.alert = false;
    this.returned = value;
  };

  <template>
    <CanonGrid>
      <CanonButton @text="Dialog" @onClick={{this.openDialog}} />
      <CanonButton @text="Alert" @onClick={{this.openAlert}} />
    </CanonGrid>
    <CanonRow
      @title="Returned"
      @detail={{if this.returned this.returned "—"}}
    />
    <CanonDialog
      @open={{this.dialog}}
      @title="Export palette"
      @message={{exportMessage}}
      @onClose={{this.closeDialog}}
    >
      <:default>
        <CanonRow @title="Format" @form="stacked" as |titleId|>
          <CanonSegmented @items={{formats}} aria-labelledby={{titleId}} />
        </CanonRow>
        <CanonRow @title="Include names" as |titleId|>
          <CanonSwitch @on={{true}} aria-labelledby={{titleId}} />
        </CanonRow>
      </:default>
      <:footer as |close|>
        <CanonButton @text="Cancel" @onClick={{fn close "cancel"}} />
        <CanonButton
          @text="Export"
          @selected={{true}}
          @onClick={{fn close "export"}}
        />
      </:footer>
    </CanonDialog>
    <CanonDialog
      @open={{this.alert}}
      @alert={{true}}
      @title="Delete palette?"
      @message={{deleteMessage}}
      @onClose={{this.closeAlert}}
    >
      <:footer as |close|>
        <CanonButton @text="Cancel" @onClick={{fn close "cancel"}} />
        <CanonButton
          @text="Delete"
          @selected={{true}}
          @onClick={{fn close "delete"}}
        />
      </:footer>
    </CanonDialog>
  </template>
}

const sheetEdges: { edge: CanonSheetEdge; title: string; svg: string }[] = [
  { edge: 'bottom', title: 'Bottom', svg: panelBottom },
  { edge: 'top', title: 'Top', svg: panelTop },
  { edge: 'start', title: 'Start', svg: panelLeft },
  { edge: 'end', title: 'End', svg: panelRight },
];

class Sheet extends Component {
  @tracked sheet?: CanonSheetEdge;

  show = (edge: CanonSheetEdge) => (this.sheet = edge);
  close = () => (this.sheet = undefined);
  isOpen = (edge: CanonSheetEdge) => this.sheet === edge;

  <template>
    <CanonGrid>
      {{#each sheetEdges as |e|}}
        <CanonButton
          @text={{e.title}}
          @icon={{component Icon svg=e.svg}}
          @onClick={{fn this.show e.edge}}
        />
      {{/each}}
    </CanonGrid>
    {{#each sheetEdges as |e|}}
      <CanonSheet
        @open={{this.isOpen e.edge}}
        @edge={{e.edge}}
        @title={{e.title}}
        @onClose={{this.close}}
      >
        <:default>
          <CanonRow @title="Snap to grid" as |titleId|>
            <CanonSwitch @on={{true}} aria-labelledby={{titleId}} />
          </CanonRow>
          <CanonRow @title="Show rulers" as |titleId|>
            <CanonSwitch aria-labelledby={{titleId}} />
          </CanonRow>
          <CanonRow @title="Units" @form="stacked" as |titleId|>
            <CanonSegmented @items={{units}} aria-labelledby={{titleId}} />
          </CanonRow>
        </:default>
        <:footer as |close|>
          <CanonButton @text="Done" @onClick={{fn close ""}} />
        </:footer>
      </CanonSheet>
    {{/each}}
  </template>
}

const CopyIcon = <template><Icon @svg={{copy}} /></template>;
const PencilIcon = <template><Icon @svg={{pencil}} /></template>;
const ShareIcon = <template><Icon @svg={{share}} /></template>;
const TrashIcon = <template><Icon @svg={{trash}} /></template>;
const separator = { kind: 'separator' } as const;
const menuSizes = ['Small', 'Medium', 'Large'];

class MenuState extends Component {
  @tracked chosen = '—';
  @tracked grid = true;
  @tracked snap = false;
  @tracked rulers = false;
  @tracked size = 'Medium';

  get items(): CanonMenuEntry[] {
    return [
      { title: 'Duplicate', icon: CopyIcon, shortcut: '⌘D' },
      { title: 'Rename…', icon: PencilIcon },
      {
        title: 'Share',
        icon: ShareIcon,
        items: [
          { title: 'Copy link' },
          { title: 'Email' },
          { title: 'Messages' },
        ],
      },
      separator,
      { title: 'Grid', kind: 'checkbox', checked: this.grid, shortcut: "⌘'" },
      { title: 'Snap', kind: 'checkbox', checked: this.snap },
      separator,
      ...menuSizes.map((title) => ({
        title,
        kind: 'radio' as const,
        checked: this.size === title,
      })),
      separator,
      { title: 'Rasterise', disabled: true },
      { title: 'Delete', icon: TrashIcon, destructive: true, shortcut: '⌫' },
    ];
  }

  get menus(): CanonMenuBarMenu[] {
    return [
      {
        title: 'File',
        items: [
          { title: 'New', shortcut: '⌘N' },
          { title: 'Open…', shortcut: '⌘O' },
          {
            title: 'Open recent',
            items: [{ title: 'Poster.pdf' }, { title: 'Letter.pdf' }],
          },
          separator,
          { title: 'Close', shortcut: '⌘W' },
        ],
      },
      {
        title: 'Edit',
        items: [
          { title: 'Undo', shortcut: '⌘Z' },
          { title: 'Redo', shortcut: '⇧⌘Z', disabled: true },
          separator,
          { title: 'Cut', shortcut: '⌘X' },
          { title: 'Copy', shortcut: '⌘C' },
          { title: 'Paste', shortcut: '⌘V' },
        ],
      },
      {
        title: 'View',
        items: [
          { title: 'Grid', kind: 'checkbox', checked: this.grid },
          { title: 'Rulers', kind: 'checkbox', checked: this.rulers },
          separator,
          {
            title: 'Zoom',
            items: [
              { title: 'Zoom in', shortcut: '⌘+' },
              { title: 'Zoom out', shortcut: '⌘−' },
              { title: 'Fit', shortcut: '⌘0' },
            ],
          },
        ],
      },
      { title: 'Help', items: [{ title: 'About' }] },
    ];
  }

  choose = (item: CanonMenuItem) => {
    this.chosen = item.title;
    if (item.title === 'Grid') this.grid = !this.grid;
    if (item.title === 'Snap') this.snap = !this.snap;
    if (item.title === 'Rulers') this.rulers = !this.rulers;
    if (item.kind === 'radio') this.size = item.title;
  };
}

class Menu extends MenuState {
  <template>
    <CanonRow @title="Dropdown" @form="flush">
      <CanonMenu @items={{this.items}} @onSelect={{this.choose}} as |menu|>
        <CanonButton
          {{menu.trigger}}
          @kind="cell"
          @text="Actions"
          @icon={{component Icon svg=chevronDown}}
        />
      </CanonMenu>
    </CanonRow>
    <CanonRow @title="Chosen" @detail={{this.chosen}} />
  </template>
}

class ContextMenu extends MenuState {
  <template>
    <CanonContextMenu
      class="gallery-context-area"
      tabindex="0"
      aria-label="Context area"
      @items={{this.items}}
      @onSelect={{this.choose}}
    >
      <CanonCanvas @height={{160}}><GalleryArt
          @label="Right click"
        /></CanonCanvas>
    </CanonContextMenu>
    <CanonRow @title="Chosen" @detail={{this.chosen}} />
  </template>
}

class MenuBar extends MenuState {
  <template>
    <CanonMenuBar
      aria-label="Showcase"
      @menus={{this.menus}}
      @onSelect={{this.choose}}
    />
    <CanonRow @title="Chosen" @detail={{this.chosen}} />
  </template>
}

const sides = ['Top', 'Right', 'Bottom', 'Left'];
const alignments = ['Start', 'Centre', 'End'];

class Popover extends Component {
  @tracked side = 2;
  @tracked edge = 0;
  @tracked opacity = 0.8;

  get placement(): CanonPlacement {
    const side = ['top', 'right', 'bottom', 'left'][this.side]!;
    const edge = ['-start', '', '-end'][this.edge]!;
    return `${side}${edge}` as CanonPlacement;
  }

  pickSide = (index: number) => (this.side = index);
  pickEdge = (index: number) => (this.edge = index);
  setOpacity = (value: number) => (this.opacity = value);

  <template>
    <CanonRow @title="Side" @form="stacked">
      <CanonSegmented
        @items={{sides}}
        @selected={{this.side}}
        @onChange={{this.pickSide}}
      />
    </CanonRow>
    <CanonRow @title="Edge" @form="stacked">
      <CanonSegmented
        @items={{alignments}}
        @selected={{this.edge}}
        @onChange={{this.pickEdge}}
      />
    </CanonRow>
    <CanonGrid>
      <CanonPopover
        class="gallery-popover"
        role="dialog"
        aria-label="Opacity"
        @placement={{this.placement}}
      >
        <:trigger as |popover|>
          <CanonButton {{popover.trigger}} @kind="cell" @text="Popover" />
        </:trigger>
        <:content as |popover|>
          <CanonRows>
            <CanonRow @title="Opacity" @form="stacked">
              <CanonSlider
                @value={{this.opacity}}
                @label="Opacity"
                @onChange={{this.setOpacity}}
              />
            </CanonRow>
            <CanonButton
              @kind="primary"
              @text="Done"
              @onClick={{popover.close}}
            />
          </CanonRows>
        </:content>
      </CanonPopover>
    </CanonGrid>
  </template>
}

const Tooltips = <template>
  <CanonGrid>
    <CanonTooltip @text="Copy" as |tip|>
      <CanonButton
        {{tip.trigger}}
        @kind="cell"
        @label="Copy"
        @icon={{component Icon svg=copy}}
      />
    </CanonTooltip>
    <CanonTooltip @text="Share" as |tip|>
      <CanonButton
        {{tip.trigger}}
        @kind="cell"
        @label="Share"
        @icon={{component Icon svg=share}}
      />
    </CanonTooltip>
    <CanonTooltip @text="Delete" as |tip|>
      <CanonButton
        {{tip.trigger}}
        @kind="cell"
        @label="Delete"
        @icon={{component Icon svg=trash}}
      />
    </CanonTooltip>
  </CanonGrid>
</template>;

const modules: { title: string; svg: string; light: CanonSidebarLight }[] = [
  { title: 'Clipboard', svg: clipboard, light: 'on' },
  { title: 'Capture', svg: camera, light: 'warning' },
  { title: 'Hotkeys', svg: keyboard, light: 'off' },
  { title: 'Loupe', svg: aperture, light: 'on' },
];

const SidebarRows: TOC<{
  Args: {
    selected: string;
    onPick: (title: string, event: MouseEvent) => void;
  };
}> = <template>
  <CanonSidebarRow
    @title="Toolbox"
    @icon={{component Icon svg=wrench}}
    @selected={{eq @selected "Toolbox"}}
    @onClick={{fn @onPick "Toolbox"}}
  />
  <CanonHeading @text="Modules" />
  {{#each modules as |row|}}
    <CanonSidebarRow
      @title={{row.title}}
      @icon={{component Icon svg=row.svg}}
      @light={{row.light}}
      @selected={{eq @selected row.title}}
      @onClick={{fn @onPick row.title}}
    />
  {{/each}}
  <CanonSidebarRow
    @title="General"
    @icon={{component Icon svg=settings}}
    @href="#general"
    @selected={{eq @selected "General"}}
    @onClick={{fn @onPick "General"}}
  />
</template>;

class Pick extends Component {
  @tracked selected = 'Toolbox';

  pick = (title: string, event: MouseEvent) => {
    event.preventDefault();
    this.selected = title;
  };
}

class Sidebar extends Pick {
  @tracked collapsed = false;

  collapse = (on: boolean) => (this.collapsed = on);

  <template>
    <div class="showcase-sidebar-box">
      <CanonSidebar @collapsed={{this.collapsed}} aria-label="Showcase">
        <:hero><div class="gallery-shell-hero"><GalleryArt
              @label="Hero"
            /></div></:hero>
        <:default>
          <SidebarRows @selected={{this.selected}} @onPick={{this.pick}} />
        </:default>
      </CanonSidebar>
    </div>
    <CanonRow @title="Rail" as |titleId|>
      <CanonSwitch
        @on={{this.collapsed}}
        @onChange={{this.collapse}}
        aria-labelledby={{titleId}}
      />
    </CanonRow>
  </template>
}

class SidebarRow extends Pick {
  <template>
    <div class="showcase-sidebar-rows">
      <SidebarRows @selected={{this.selected}} @onPick={{this.pick}} />
    </div>
  </template>
}

const windowMenus: CanonMenuBarMenu[] = [
  {
    title: 'File',
    items: [
      { title: 'New', shortcut: '⌘N' },
      { title: 'Close', shortcut: '⌘W' },
    ],
  },
  {
    title: 'Edit',
    items: [
      { title: 'Undo', shortcut: '⌘Z' },
      { title: 'Copy', shortcut: '⌘C' },
    ],
  },
  {
    title: 'View',
    items: [{ title: 'Sidebar', kind: 'checkbox', checked: true }],
  },
];

class Window extends Pick {
  // undefined follows the window's width
  @tracked collapsed?: true;
  @tracked closed = false;
  @tracked minimised = false;
  @tracked zoomed = false;

  toggle = () => (this.collapsed = this.collapsed ? undefined : true);
  close = () => (this.closed = true);
  reopen = () => (this.closed = false);
  minimise = () => (this.minimised = !this.minimised);
  zoom = () => (this.zoomed = !this.zoomed);

  <template>
    {{#if this.closed}}
      <CanonButton @text="Reopen" @onClick={{this.reopen}} />
    {{else}}
      <CanonWindow
        class="gallery-shell-window
          {{if this.minimised 'gallery-shell--minimised'}}
          {{if this.zoomed 'gallery-shell--zoomed'}}"
        @title="Delphi"
        @onClose={{this.close}}
        @onMinimise={{this.minimise}}
        @onZoom={{this.zoom}}
      >
        <:toolbar>
          <CanonButton
            @kind="cell"
            @icon={{component Icon svg=panelLeft}}
            @label="Sidebar"
            @selected={{this.collapsed}}
            aria-pressed={{if this.collapsed "true" "false"}}
            @onClick={{this.toggle}}
          />
        </:toolbar>
        <:menubar>
          <CanonMenuBar @menus={{windowMenus}} aria-label="Delphi" />
        </:menubar>
        <:sidebar>
          <CanonSidebar @collapsed={{this.collapsed}} aria-label="Main">
            <:hero><div class="gallery-shell-hero"><GalleryArt
                  @label="Hero"
                /></div></:hero>
            <:default>
              <SidebarRows @selected={{this.selected}} @onPick={{this.pick}} />
            </:default>
          </CanonSidebar>
        </:sidebar>
        <:main>
          <CanonPage>
            <CanonCanvas @aspect={{3}}><GalleryArt
                @label={{this.selected}}
              /></CanonCanvas>
          </CanonPage>
        </:main>
      </CanonWindow>
    {{/if}}
  </template>
}

export interface Tile {
  /** The registry item name and the addon module, `canon-<name>`. */
  name: string;
  Live: ComponentLike;
}

export const tiles: Tile[] = [
  { name: 'canon-bar', Live: Bar },
  { name: 'canon-big-number-field', Live: BigNumber },
  { name: 'canon-button', Live: Buttons },
  { name: 'canon-canvas', Live: Canvas },
  { name: 'canon-code-block', Live: CodeBlock },
  { name: 'canon-colour-card', Live: ColourCard },
  { name: 'canon-colour-controls', Live: ColourControls },
  { name: 'canon-colour-notation-input', Live: ColourNotation },
  { name: 'canon-colour-solid', Live: ColourSolid },
  { name: 'canon-colour-strip', Live: ColourStrip },
  { name: 'canon-colour-well', Live: ColourWells },
  { name: 'canon-command', Live: Command },
  { name: 'canon-context-menu', Live: ContextMenu },
  { name: 'canon-decimal-field', Live: DecimalField },
  { name: 'canon-detent-wheel', Live: DetentWheel },
  { name: 'canon-detent-wheel-row', Live: DetentWheelRows },
  { name: 'canon-dialog', Live: Dialog },
  { name: 'canon-drop-zone', Live: DropZone },
  { name: 'canon-dual-list', Live: DualList },
  { name: 'canon-empty-row', Live: EmptyRow },
  { name: 'canon-figure', Live: Figure },
  { name: 'canon-file-cell', Live: FileCell },
  { name: 'canon-from-to', Live: FromTo },
  { name: 'canon-glyph-flow', Live: GlyphFlow },
  { name: 'canon-grid', Live: Grid },
  { name: 'canon-heading', Live: Heading },
  { name: 'canon-icon', Live: Icons },
  { name: 'canon-image-compare', Live: ImageCompare },
  { name: 'canon-lamps', Live: Lamps },
  { name: 'canon-loader', Live: Loaders },
  { name: 'canon-loupe', Live: Loupe },
  { name: 'canon-math-editor', Live: MathEditor },
  { name: 'canon-math-field', Live: MathField },
  { name: 'canon-math-input', Live: MathInput },
  { name: 'canon-math-key', Live: MathKeys },
  { name: 'canon-math-keypad', Live: MathKeypad },
  { name: 'canon-math-rail', Live: MathRail },
  { name: 'canon-math-tabs', Live: MathTabs },
  { name: 'canon-math-view', Live: MathView },
  { name: 'canon-menu', Live: Menu },
  { name: 'canon-menu-bar', Live: MenuBar },
  { name: 'canon-menu-cell', Live: MenuCell },
  { name: 'canon-number-field', Live: NumberField },
  { name: 'canon-page', Live: Page },
  { name: 'canon-page-strip', Live: PageStrip },
  { name: 'canon-palette-card', Live: PaletteCard },
  { name: 'canon-popover', Live: Popover },
  { name: 'canon-preview-panel', Live: PreviewPanel },
  { name: 'canon-readout-band', Live: ReadoutBand },
  { name: 'canon-row', Live: Row },
  { name: 'canon-rows', Live: Rows },
  { name: 'canon-rule', Live: Rule },
  { name: 'canon-segmented', Live: Segmented },
  { name: 'canon-sheet', Live: Sheet },
  { name: 'canon-sidebar', Live: Sidebar },
  { name: 'canon-sidebar-row', Live: SidebarRow },
  { name: 'canon-slider', Live: Slider },
  { name: 'canon-split', Live: Split },
  { name: 'canon-status', Live: Status },
  { name: 'canon-stepper', Live: Stepper },
  { name: 'canon-swatch', Live: Swatches },
  { name: 'canon-switch', Live: Switches },
  { name: 'canon-text-area', Live: TextArea },
  { name: 'canon-text-cell', Live: TextCell },
  { name: 'canon-text-input', Live: TextInput },
  { name: 'canon-text-output', Live: TextOutput },
  { name: 'canon-tiles', Live: Tiles },
  { name: 'canon-timecode', Live: Timecodes },
  { name: 'canon-toast', Live: Toast },
  { name: 'canon-tooltip', Live: Tooltips },
  { name: 'canon-value-line', Live: ValueLines },
  { name: 'canon-window', Live: Window },
];
