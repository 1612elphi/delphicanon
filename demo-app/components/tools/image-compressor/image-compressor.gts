import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { registerDestructor } from '@ember/destroyable';
import type Owner from '@ember/owner';
import CanonButton from '#src/components/canon-button.gts';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonDropZone from '#src/components/canon-drop-zone.gts';
import CanonEmptyRow from '#src/components/canon-empty-row.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonImageCompare from '#src/components/canon-image-compare.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonSegmented from '#src/components/canon-segmented.gts';
import CanonSlider from '#src/components/canon-slider.gts';
import CanonSplit from '#src/components/canon-split.gts';
import { accepts } from '#src/lib/files.ts';
import {
  availableFormats,
  Encoder,
  exportName,
  formatBytes,
  type EncodeReply,
} from './compress.ts';
import Scale from './scale.gts';
import Icon from '../../icon.gts';
import './image-compressor.css';
import shrink from 'lucide-static/icons/shrink.svg?raw';
import download from 'lucide-static/icons/download.svg?raw';
import trash from 'lucide-static/icons/trash-2.svg?raw';

export const tool = {
  title: 'Image compressor',
  group: 'Images & Assets',
  icon: shrink,
};

const formats = availableFormats();
const formatLabels = formats.map((format) => format.label);

// ?compressSample: a drawn 1600 x 1200 PNG, the iOS -compresssample flag; ?compressFormat=<index> ?compressQuality=<1-100>
const query = new URLSearchParams(window.location.search);
const sample = query.has('compressSample');
const webp = formats.findIndex((format) => format.type === 'image/webp');
const startFormat =
  Number(query.get('compressFormat') ?? (webp < 0 ? 0 : webp)) || 0;
const startQuality = Number(query.get('compressQuality') ?? 75) || 75;

// ∑CG: main pane, empty row where the comparison appears once an image is loaded
//   spec: says the comparison needs an image; the iOS "Add an image to compare"; at most 32 chars, no period
//   sample: "Add an image to compare"
const placeholderText = '∑CG';

// ∑CG: over the dimmed original when the chosen format cannot encode it
//   spec: the iOS "This format couldn't encode this image"; one sentence, at most 48 chars, no period
//   sample: "This format couldn't encode this image"
const encodeFailure = '∑CG';

// ∑CG: over the empty comparison when the file cannot be decoded as an image
//   spec: says the file could not be read as an image; one sentence, at most 48 chars, no period
//   sample: "This file couldn't be read as an image"
const decodeFailure = '∑CG';

const qualityReadout = (value: number) => String(Math.round(value));

const Download = <template><Icon @svg={{download}} /></template>;
const Trash = <template><Icon @svg={{trash}} /></template>;

interface Source {
  id: number;
  file: File;
  url: string;
  width?: number;
  height?: number;
}

async function drawnSample(): Promise<File> {
  const canvas = document.createElement('canvas');
  canvas.width = 1600;
  canvas.height = 1200;
  const context = canvas.getContext('2d')!;
  const sky = context.createLinearGradient(0, 0, 1600, 1200);
  sky.addColorStop(0, '#1d3b8f');
  sky.addColorStop(0.55, '#e07a3f');
  sky.addColorStop(1, '#f6d58e');
  context.fillStyle = sky;
  context.fillRect(0, 0, 1600, 1200);
  for (let i = 0; i < 24; i++) {
    context.fillStyle = `hsl(${i * 15} 70% 55% / 0.7)`;
    context.beginPath();
    context.arc(100 + i * 60, 600 + Math.sin(i) * 300, 40 + i * 4, 0, 7);
    context.fill();
  }
  const blob = await new Promise<Blob | null>((resolve) =>
    canvas.toBlob(resolve, 'image/png'),
  );
  return new File([blob!], 'sample.png', { type: 'image/png' });
}

/** The port of ImageCompressorViewController. */
export default class ImageCompressor extends Component {
  @tracked source?: Source;
  @tracked formatIndex = Math.min(startFormat, formats.length - 1);
  @tracked quality = Math.min(Math.max(startQuality, 1), 100);
  @tracked result?: { blob: Blob; url: string };
  @tracked working = false;
  /** undefined, or the failure shown over the comparison. */
  @tracked failure?: string;
  #sources = 0;
  #timer?: number;
  #encoder = new Encoder((reply) => this.#received(reply));

  constructor(owner: Owner, args: object) {
    super(owner, args);
    const paste = (event: ClipboardEvent) => {
      const file = [...(event.clipboardData?.files ?? [])].find((f) =>
        accepts(f, 'image/*'),
      );
      if (!file) return;
      event.preventDefault();
      void this.load(file);
    };
    document.addEventListener('paste', paste);
    registerDestructor(this, () => {
      document.removeEventListener('paste', paste);
      window.clearTimeout(this.#timer);
      this.#encoder.destroy();
      this.#revoke();
    });
    if (sample) void drawnSample().then((file) => this.load(file));
  }

  get format() {
    return formats[this.formatIndex]!;
  }

  get meta() {
    const { source } = this;
    if (!source) return '';
    const size = formatBytes(source.file.size);
    return source.width ? `${source.width} × ${source.height} · ${size}` : size;
  }

  get aspect() {
    const { source } = this;
    return source?.width && source.height
      ? Math.max(1, source.width / source.height)
      : 1.5;
  }

  get resultBytes() {
    return this.result?.blob.size ?? 0;
  }

  get downloadName() {
    return this.source ? exportName(this.source.file.name, this.format) : '';
  }

  loadFiles = (files: File[]) => {
    if (files[0]) void this.load(files[0]);
  };

  async load(file: File) {
    this.clear();
    const source: Source = {
      id: ++this.#sources,
      file,
      url: URL.createObjectURL(file),
    };
    this.source = source;
    this.working = true;
    const image = new Image();
    image.src = source.url;
    try {
      await image.decode();
    } catch {
      if (this.source !== source) return;
      this.working = false;
      this.failure = decodeFailure;
      return;
    }
    if (this.source !== source) return;
    this.source = {
      ...source,
      width: image.naturalWidth,
      height: image.naturalHeight,
    };
    this.#compress(0);
  }

  clear = () => {
    window.clearTimeout(this.#timer);
    this.#encoder.cancel();
    this.#revoke();
    this.source = undefined;
    this.result = undefined;
    this.failure = undefined;
    this.working = false;
  };

  pickFormat = (index: number) => {
    if (index === this.formatIndex) return;
    this.formatIndex = index;
    this.#compress(0);
  };

  pickQuality = (value: number) => {
    if (value === this.quality) return;
    this.quality = value;
    this.#compress(250);
  };

  save = () => {
    if (!this.result) return;
    const link = document.createElement('a');
    link.href = this.result.url;
    link.download = this.downloadName;
    link.click();
  };

  #compress(delay: number) {
    const { source } = this;
    if (!source?.width) return;
    window.clearTimeout(this.#timer);
    this.#encoder.cancel();
    this.failure = undefined;
    this.working = true;
    const { type } = this.format;
    const { quality } = this;
    this.#timer = window.setTimeout(
      () =>
        this.#encoder.send({
          source: source.id,
          file: source.file,
          type,
          quality,
        }),
      delay,
    );
  }

  #received(reply: EncodeReply) {
    this.working = false;
    if (this.result) URL.revokeObjectURL(this.result.url);
    if ('error' in reply) {
      this.result = undefined;
      this.failure = encodeFailure;
      return;
    }
    this.result = { blob: reply.blob, url: URL.createObjectURL(reply.blob) };
  }

  #revoke() {
    if (this.source) URL.revokeObjectURL(this.source.url);
    if (this.result) URL.revokeObjectURL(this.result.url);
  }

  <template>
    <CanonSplit class="image-compressor">
      <:banner>
        <CanonCanvas @height={{176}}>
          <Scale
            @before={{if this.source this.source.file.size 0}}
            @after={{this.resultBytes}}
            @format={{if this.source this.format.label "Compressed"}}
            @working={{this.working}}
          />
        </CanonCanvas>
      </:banner>
      <:sidebar>
        <CanonRows @framed={{true}}>
          {{#if this.source}}
            <CanonHeading @text="Source" />
            <CanonRow
              class="ic-source"
              @title={{this.source.file.name}}
              @detail={{this.meta}}
              @form="flush"
            >
              <CanonButton
                @kind="cell"
                @text="Clear"
                @icon={{Trash}}
                @onClick={{this.clear}}
              />
            </CanonRow>
            <CanonHeading @text="Format" />
            <CanonSegmented
              @items={{formatLabels}}
              @selected={{this.formatIndex}}
              @onChange={{this.pickFormat}}
            />
            {{#if this.format.hasQuality}}
              <CanonRow @title="Quality" @form="flush" as |titleId|>
                <CanonSlider
                  @value={{this.quality}}
                  @min={{1}}
                  @max={{100}}
                  @step={{1}}
                  @readout={{qualityReadout}}
                  @labelledBy={{titleId}}
                  @onChange={{this.pickQuality}}
                />
              </CanonRow>
            {{/if}}
            <CanonButton
              @kind="primary"
              @text="Download"
              @icon={{Download}}
              @disabled={{if this.result false true}}
              @onClick={{this.save}}
            />
          {{else}}
            <CanonDropZone
              @prompt="Drop an image"
              @paste={{false}}
              @onFiles={{this.loadFiles}}
            />
          {{/if}}
        </CanonRows>
      </:sidebar>
      <:main>
        {{#if this.source}}
          <CanonCanvas
            @aspect={{this.aspect}}
            @boxing="unlessWide"
            @background="var(--canon-muted)"
          >
            <CanonImageCompare
              @before={{if this.source.width this.source.url}}
              @after={{this.result.url}}
              @failed={{if this.failure true false}}
              @failure={{this.failure}}
            />
          </CanonCanvas>
        {{else}}
          <CanonRows @framed={{true}}>
            <CanonEmptyRow @text={{placeholderText}} />
          </CanonRows>
        {{/if}}
      </:main>
    </CanonSplit>
  </template>
}
