import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { registerDestructor } from '@ember/destroyable';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import type Owner from '@ember/owner';
import CanonButton from '#src/components/canon-button.gts';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonColourWell from '#src/components/canon-colour-well.gts';
import CanonDropZone from '#src/components/canon-drop-zone.gts';
import CanonGrid from '#src/components/canon-grid.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonNumberField from '#src/components/canon-number-field.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonSegmented from '#src/components/canon-segmented.gts';
import CanonSlider from '#src/components/canon-slider.gts';
import CanonSplit from '#src/components/canon-split.gts';
import CanonStatus from '#src/components/canon-status.gts';
import CanonTiles from '#src/components/canon-tiles.gts';
import { parseHex, type Rgb } from '#src/lib/colour.ts';
import { stem } from '#src/lib/files.ts';
import { springEasing } from '#src/lib/motion.ts';
import Icon from '../../icon.gts';
import {
  bytes,
  defaultDominant,
  fileName,
  fit,
  heightOf,
  maxRatio,
  minWidth,
  ratios,
  solid,
  widthLimit,
  widths,
  type Bytes,
  type MatteSpec,
  type MatteStyle,
  type Size,
} from './matte.ts';
import type { MatteReply, MatteRequest } from './matte-worker.ts';
import Picture from './picture.gts';
import './matte-genny.css';
import square from 'lucide-static/icons/square.svg?raw';
import download from 'lucide-static/icons/download.svg?raw';
import swapIcon from 'lucide-static/icons/arrow-left-right.svg?raw';
import trash from 'lucide-static/icons/trash-2.svg?raw';

export const tool = {
  title: 'Matte generator',
  group: 'Social Media',
  icon: square,
};

// ∑CG: status row under the drop zone when a file does not decode as an image
//   spec: says the file could not be read as an image and to try another; one sentence, at most 48 chars, plain, no blame
//   sample: "That file is not an image this browser reads."
const loadFailed = '∑CG';

// ?matteStyle=<0 blur, 1 solid, 2 gradient> ?matteRatio=16:9 ?matteWidth=<px> ?mattePadding=<px> ?matteColour=%231e6626: the iOS -mattestyle, -matteratio, -mattewidth, -mattepadding, -mattecolour flags
const query = new URLSearchParams(window.location.search);
const flag = (name: string) => {
  const value = query.get(name);
  return value === null ? undefined : Number(value);
};
const flaggedRatio = (query.get('matteRatio') ?? '')
  .split(':')
  .map(Number)
  .filter((side) => side > 0);

// iOS: spring over 0.5 s, damping 0.82
const spring = htmlSafe(`--matte-spring: ${springEasing(0.82)}`);

const styleNames = ['Blur', 'Solid', 'Gradient'];
const ratioNames = [...ratios.map(([w, h]) => `${w}:${h}`), 'Custom'];
const widthNames = widths.map(String);
const clampRatio = (side: number) =>
  Math.min(Math.max(Math.round(side), 1), maxRatio);
const sameRatio = ([a, b]: [number, number], w: number, h: number) =>
  (a === w && b === h) || (a === h && b === w);
const pixelsText = (value: number) => `${value} px`;

const Download = <template><Icon @svg={{download}} /></template>;
const Swap = <template><Icon @svg={{swapIcon}} /></template>;
const Trash = <template><Icon @svg={{trash}} /></template>;

/**
 * CanonSplit's collapsing picture measures the canvas aspect only on scroll
 * and resize; a scroll event makes it take a new ratio, eased for 500 ms.
 */
const refit = modifier((canvas: HTMLElement, [aspect]: [number]) => {
  const split = canvas.closest<HTMLElement>('.canon-split');
  const body = split?.querySelector('.canon-split-body');
  if (!split || !body || split.dataset['aspect'] === String(aspect)) return;
  const first = split.dataset['aspect'] === undefined;
  split.dataset['aspect'] = String(aspect);
  if (first) return;
  split.classList.add('matte-refit');
  body.dispatchEvent(new Event('scroll'));
  const timer = window.setTimeout(
    () => split.classList.remove('matte-refit'),
    500,
  );
  return () => window.clearTimeout(timer);
});

interface Source {
  url: string;
  pixels: Size;
  stem: string;
}

/** The port of MatteGeneratorViewController. */
export default class MatteGenny extends Component {
  @tracked style = ((flag('matteStyle') ?? 0) % 3) as MatteStyle;
  @tracked colour: Rgb = parseHex(query.get('matteColour') ?? '') ?? [1, 1, 1];
  @tracked ratioW =
    flaggedRatio.length === 2 ? clampRatio(flaggedRatio[0]!) : 1;
  @tracked ratioH =
    flaggedRatio.length === 2 ? clampRatio(flaggedRatio[1]!) : 1;
  @tracked isCustom = !ratios.some((pair) =>
    sameRatio(pair, this.ratioW, this.ratioH),
  );
  @tracked widthValue = flag('matteWidth') ?? 1080;
  @tracked padding = Math.min(Math.max(flag('mattePadding') ?? 40, 0), 200);
  @tracked dominant: Bytes = defaultDominant;
  @tracked source?: Source;
  @tracked failed = false;
  @tracked exporting = false;
  @tracked guides = false;

  #worker = new Worker(new URL('./matte-worker.ts', import.meta.url), {
    type: 'module',
  });
  #request = 0;
  #loading = 0;
  #exporting = 0;
  #pending?: { url: string; stem: string };
  #guideTimer?: number;
  #typingTimer?: number;
  #typed = false;

  constructor(owner: Owner, args: object) {
    super(owner, args);
    this.#worker.onmessage = (event: MessageEvent<MatteReply>) =>
      this.#reply(event.data);
    // a worker that fails to start or throws leaves nothing busy
    this.#worker.onerror = () => {
      this.#exporting = 0;
      this.exporting = false;
    };
    const paste = (event: ClipboardEvent) => {
      if (event.defaultPrevented) return;
      const file = [...(event.clipboardData?.files ?? [])].find((f) =>
        f.type.startsWith('image/'),
      );
      if (!file) return;
      event.preventDefault();
      this.load([file]);
    };
    window.addEventListener('paste', paste);
    registerDestructor(this, () => {
      window.removeEventListener('paste', paste);
      window.clearTimeout(this.#guideTimer);
      window.clearTimeout(this.#typingTimer);
      this.#worker.terminate();
      if (this.#pending) URL.revokeObjectURL(this.#pending.url);
      if (this.source) URL.revokeObjectURL(this.source.url);
    });
  }

  get limit() {
    return widthLimit(this.ratioW, this.ratioH);
  }

  get width() {
    return Math.min(Math.max(this.widthValue, minWidth), this.limit);
  }

  get spec(): MatteSpec {
    return {
      style: this.style,
      colour: bytes(this.colour),
      dominant: this.dominant,
      ratioW: this.ratioW,
      ratioH: this.ratioH,
      width: this.width,
      padding: this.padding,
    };
  }

  get height() {
    return heightOf(this.width, this.ratioW, this.ratioH);
  }

  get aspect() {
    return Math.min(1.5, Math.max(0.8, this.ratioW / this.ratioH));
  }

  get ratioIndex() {
    if (this.isCustom) return ratios.length;
    const index = ratios.findIndex((pair) =>
      sameRatio(pair, this.ratioW, this.ratioH),
    );
    return index < 0 ? ratios.length : index;
  }

  get widthIndex() {
    return widths.indexOf(this.width);
  }

  get shape() {
    if (this.ratioW === this.ratioH) return 'Square';
    return this.ratioW > this.ratioH ? 'Landscape' : 'Portrait';
  }

  get square() {
    return this.ratioW === this.ratioH;
  }

  get isSolid() {
    return this.style === solid;
  }

  get ratioText() {
    return `${this.ratioW}:${this.ratioH}`;
  }

  get sourceText() {
    const pixels = this.source?.pixels;
    return pixels ? `${pixels.width} × ${pixels.height}` : '';
  }

  get tiles() {
    const { source } = this;
    if (!source) return [];
    const photo = fit(
      source.pixels,
      { width: this.width, height: this.height },
      this.padding,
    );
    return [
      { label: 'Source', value: this.sourceText },
      {
        label: 'Photo',
        value: `${Math.round(photo.width)} × ${Math.round(photo.height)}`,
      },
      {
        label: 'Scale',
        value: `${Math.round((photo.width / source.pixels.width) * 100)} %`,
      },
    ];
  }

  #post(request: MatteRequest) {
    this.#worker.postMessage(request);
  }

  #reply(reply: MatteReply) {
    if (reply.id === this.#exporting) {
      this.#exporting = 0;
      this.exporting = false;
      if (reply.kind === 'rendered' && this.source)
        save(reply.blob, fileName(this.source.stem, this.width, this.height));
      return;
    }
    const pending = this.#pending;
    if (reply.id !== this.#loading || !pending) return;
    this.#loading = 0;
    this.#pending = undefined;
    if (reply.kind !== 'loaded') {
      URL.revokeObjectURL(pending.url);
      this.clear();
      this.failed = true;
      return;
    }
    if (this.source) URL.revokeObjectURL(this.source.url);
    this.source = {
      url: pending.url,
      stem: pending.stem,
      pixels: { width: reply.width, height: reply.height },
    };
    this.dominant = reply.dominant;
    this.failed = false;
  }

  load = (files: File[]) => {
    const [file] = files;
    if (!file) return;
    if (this.#pending) URL.revokeObjectURL(this.#pending.url);
    this.#pending = {
      url: URL.createObjectURL(file),
      stem: stem(file.name) || 'image',
    };
    this.#loading = ++this.#request;
    this.#post({ kind: 'load', id: this.#loading, file });
  };

  clear = () => {
    if (this.#pending) URL.revokeObjectURL(this.#pending.url);
    if (this.source) URL.revokeObjectURL(this.source.url);
    this.#pending = undefined;
    this.#loading = 0;
    this.#exporting = 0;
    this.source = undefined;
    this.dominant = defaultDominant;
    this.failed = false;
    this.exporting = false;
  };

  pickStyle = (index: number) => (this.style = index as MatteStyle);

  pickColour = (colour: Rgb) => (this.colour = colour);

  pickRatio = (index: number) => {
    window.clearTimeout(this.#typingTimer);
    this.isCustom = index === ratios.length;
    if (this.isCustom) return;
    const [short, long] = ratios[index]!;
    // keeps the current orientation
    [this.ratioW, this.ratioH] =
      this.ratioW > this.ratioH ? [long, short] : [short, long];
  };

  swap = () => {
    window.clearTimeout(this.#typingTimer);
    [this.ratioW, this.ratioH] = [this.ratioH, this.ratioW];
  };

  // iOS debounces typing only; steps and arrow keys apply at once
  noteTyping = (event: Event) => {
    this.#typed = (event.target as Element).matches('.canon-stepper-field');
  };

  #afterTyping(apply: () => void) {
    window.clearTimeout(this.#typingTimer);
    if (this.#typed) this.#typingTimer = window.setTimeout(apply, 400);
    else apply();
    this.#typed = false;
  }

  setAcross = (value: number) => this.#afterTyping(() => (this.ratioW = value));

  setDown = (value: number) => this.#afterTyping(() => (this.ratioH = value));

  pickWidth = (index: number) => {
    window.clearTimeout(this.#typingTimer);
    this.widthValue = widths[index]!;
  };

  setWidth = (value: number) =>
    this.#afterTyping(() => (this.widthValue = value));

  setPadding = (value: number) => {
    this.padding = value;
    this.guides = true;
    window.clearTimeout(this.#guideTimer);
    this.#guideTimer = window.setTimeout(() => (this.guides = false), 1000);
  };

  get exportDisabled() {
    return !this.source || this.exporting;
  }

  export = () => {
    if (this.exportDisabled) return;
    this.exporting = true;
    this.#exporting = ++this.#request;
    this.#post({ kind: 'render', id: this.#exporting, spec: this.spec });
  };

  <template>
    <CanonSplit
      class="gallery matte-genny"
      @halves={{true}}
      @collapsesTo={{200}}
      style={{spring}}
      {{on "input" this.noteTyping capture=true}}
    >
      <:sidebar>
        <CanonCanvas
          @aspect={{this.aspect}}
          @background="var(--canon-muted)"
          @pattern={{true}}
          {{refit this.aspect}}
        >
          <Picture
            @spec={{this.spec}}
            @photo={{this.source.url}}
            @pixels={{this.source.pixels}}
            @guides={{this.guides}}
            @busy={{this.exporting}}
          />
        </CanonCanvas>
      </:sidebar>
      <:main>
        <CanonRows @framed={{true}}>
          <CanonHeading @text="Source" />
          {{#if this.source}}
            <CanonRow
              @title={{this.source.stem}}
              @detail={{this.sourceText}}
              @form="flush"
            >
              <CanonButton
                @kind="cell"
                @text="Clear"
                @icon={{Trash}}
                @onClick={{this.clear}}
              />
            </CanonRow>
          {{else}}
            <CanonDropZone @prompt="Drop an image" @onFiles={{this.load}} />
          {{/if}}
          {{#if this.failed}}
            <CanonStatus @text={{loadFailed}} @tone="warn" @row={{true}} />
          {{/if}}
        </CanonRows>
        <CanonRows @framed={{true}}>
          <CanonHeading @text="Style" />
          <CanonSegmented
            @items={{styleNames}}
            @selected={{this.style}}
            @onChange={{this.pickStyle}}
          />
          {{#if this.isSolid}}
            <CanonColourWell
              @label="Colour"
              @colour={{this.colour}}
              @onChange={{this.pickColour}}
            />
          {{/if}}
          <CanonHeading @text="Ratio" />
          <CanonSegmented
            class="matte-ratios"
            @items={{ratioNames}}
            @selected={{this.ratioIndex}}
            @onChange={{this.pickRatio}}
          />
          {{#if this.isCustom}}
            <CanonGrid @columns={{2}}>
              <CanonNumberField
                @value={{this.ratioW}}
                @min={{1}}
                @max={{maxRatio}}
                @label="Ratio width"
                @onChange={{this.setAcross}}
              />
              <CanonNumberField
                @value={{this.ratioH}}
                @min={{1}}
                @max={{maxRatio}}
                @label="Ratio height"
                @onChange={{this.setDown}}
              />
            </CanonGrid>
          {{/if}}
          <CanonRow
            @title={{this.ratioText}}
            @detail={{this.shape}}
            @form="flush"
          >
            <CanonButton
              @kind="cell"
              @text="Swap"
              @icon={{Swap}}
              @disabled={{this.square}}
              @onClick={{this.swap}}
            />
          </CanonRow>
          <CanonHeading @text="Output" />
          <CanonSegmented
            @items={{widthNames}}
            @selected={{this.widthIndex}}
            @onChange={{this.pickWidth}}
          />
          <CanonRow @title="Width" @form="flush" as |titleId|>
            <CanonNumberField
              @value={{this.width}}
              @min={{minWidth}}
              @max={{this.limit}}
              @step={{10}}
              @unit="px"
              @labelledBy={{titleId}}
              @onChange={{this.setWidth}}
            />
          </CanonRow>
          <CanonRow @title="Padding" @form="flush" as |titleId|>
            <CanonSlider
              @value={{this.padding}}
              @min={{0}}
              @max={{200}}
              @step={{10}}
              @readout={{pixelsText}}
              @labelledBy={{titleId}}
              @onChange={{this.setPadding}}
            />
          </CanonRow>
          <CanonButton
            @kind="primary"
            @text="Export"
            @icon={{Download}}
            @iconStyle="oversized"
            @disabled={{this.exportDisabled}}
            @onClick={{this.export}}
          />
        </CanonRows>
        {{#if this.source}}
          <CanonRows @framed={{true}}>
            <CanonHeading @text="Image" />
            <CanonTiles @items={{this.tiles}} />
          </CanonRows>
        {{/if}}
      </:main>
    </CanonSplit>
  </template>
}

function save(blob: Blob, name: string) {
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = name;
  link.click();
  // the download reads the URL after the click returns
  window.setTimeout(() => URL.revokeObjectURL(url), 1000);
}
