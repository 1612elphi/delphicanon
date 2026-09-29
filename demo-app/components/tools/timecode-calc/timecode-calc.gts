import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { service } from '@ember/service';
import { registerDestructor } from '@ember/destroyable';
import type Owner from '@ember/owner';
import type CanonToastService from '#src/services/canon-toast.ts';
import CanonButton from '#src/components/canon-button.gts';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonMenuCell from '#src/components/canon-menu-cell.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonSegmented from '#src/components/canon-segmented.gts';
import CanonSplit from '#src/components/canon-split.gts';
import CanonStatus from '#src/components/canon-status.gts';
import CanonTiles from '#src/components/canon-tiles.gts';
import Icon from '../../icon.gts';
import TimecodeField from './field.gts';
import Picture from './picture.gts';
import {
  blank,
  clock,
  digitsOf,
  format,
  parse,
  parts,
  rates,
  register,
  seconds,
  type ParseResult,
  type Rate,
} from './smpte.ts';
import './timecode-calc.css';
import timer from 'lucide-static/icons/timer.svg?raw';
import copy from 'lucide-static/icons/copy.svg?raw';

export const tool = {
  title: 'Timecode calculator',
  group: 'Audio & Video',
  icon: timer,
};

// ?tcA=01:00:00;00 ?tcB=00:10:00;02 ?tcSubtract ?tcRate=29.97df: the iOS -tca, -tcb, -tcsubtract, -tcrate flags
const query = new URLSearchParams(window.location.search);
const pickedRate = rates.findIndex((rate) => rate.id === query.get('tcRate'));
const startRate = pickedRate < 0 ? 4 : pickedRate;
const startDrop = rates[startRate]!.drop;
const startA = register(digitsOf(query.get('tcA') ?? ''), startDrop);
const startB = register(digitsOf(query.get('tcB') ?? ''), startDrop);
const startSubtracts = query.has('tcSubtract');

const typingDelay = 400;
const rateLabels = rates.map((rate) => rate.label);
const operations = ['+', '−'];
const dash = '—';

function note(parsed: ParseResult, rate: Rate) {
  if (parsed.ok)
    return parsed.snappedFrom
      ? {
          tone: 'muted' as const,
          text: `Dropped frame · ${parsed.snappedFrom} → ${format(parsed.parts, rate)}`,
        }
      : undefined;
  const { error } = parsed;
  const text = {
    empty: undefined,
    'not-numeric': 'Numbers only',
    'too-many': 'Too many fields',
    'frame-range': `Frame too high · 00–${String(error.kind === 'frame-range' ? error.max : 0).padStart(2, '0')}`,
    'seconds-range': 'Seconds too high',
    'minutes-range': 'Minutes too high',
  }[error.kind];
  return text ? { tone: 'warn' as const, text } : undefined;
}

/** The port of TimecodeCalcViewController. */
export default class TimecodeCalc extends Component {
  @service('canon-toast') declare toast: CanonToastService;

  @tracked rateIndex = startRate;
  @tracked subtracts = startSubtracts;
  /** What the fields show now; the sum reads `settled`, 0.4 s after typing stops. */
  typed = { a: startA, b: startB };
  @tracked settled = { ...this.typed };
  #timer?: number;

  constructor(owner: Owner, args: object) {
    super(owner, args);
    registerDestructor(this, () => window.clearTimeout(this.#timer));
  }

  get rate() {
    return rates[this.rateIndex]!;
  }

  get parsedA() {
    return parse(this.settled.a, this.rate);
  }

  get parsedB() {
    return parse(this.settled.b, this.rate);
  }

  /** A alone gives A, B alone gives nothing. */
  get frames(): number | undefined {
    const { parsedA: a, parsedB: b } = this;
    if (!a.ok) return undefined;
    if (!b.ok) return a.frames;
    return this.subtracts ? a.frames - b.frames : a.frames + b.frames;
  }

  get result() {
    const { frames } = this;
    return frames === undefined
      ? undefined
      : format(parts(frames, this.rate), this.rate);
  }

  line(parsed: ParseResult) {
    return parsed.ok ? format(parsed.parts, this.rate) : blank(this.rate);
  }

  get lineA() {
    return this.line(this.parsedA);
  }

  get lineB() {
    return this.line(this.parsedB);
  }

  get noteA() {
    return note(this.parsedA, this.rate);
  }

  get noteB() {
    return note(this.parsedB, this.rate);
  }

  get tiles() {
    const { frames } = this;
    return [
      {
        label: 'Frames',
        value: frames === undefined ? dash : frames.toLocaleString('en'),
      },
      {
        label: 'Real time',
        value: frames === undefined ? dash : clock(seconds(frames, this.rate)),
      },
    ];
  }

  refresh() {
    window.clearTimeout(this.#timer);
    this.settled = { ...this.typed };
  }

  #type(field: 'a' | 'b', text: string) {
    this.typed = { ...this.typed, [field]: text };
    window.clearTimeout(this.#timer);
    this.#timer = window.setTimeout(() => this.refresh(), typingDelay);
  }

  typeA = (text: string) => this.#type('a', text);
  typeB = (text: string) => this.#type('b', text);

  pickRate = (index: number) => {
    this.rateIndex = index;
    this.refresh();
  };

  pickOperation = (index: number) => {
    this.subtracts = index === 1;
    this.refresh();
  };

  copyResult = () => {
    if (this.result) void this.toast.write(this.result).catch(() => undefined);
  };

  <template>
    <CanonSplit class="timecode-calc">
      <:banner>
        <CanonCanvas @fitting={{true}}>
          <Picture
            @a={{this.lineA}}
            @b={{this.lineB}}
            @subtracts={{this.subtracts}}
            @result={{if this.result this.result (blank this.rate)}}
          />
        </CanonCanvas>
      </:banner>
      <:sidebar>
        <CanonRows @framed={{true}}>
          <CanonHeading @text="Frame rate" />
          <CanonRow @title="Frame rate" @form="flush" as |titleId|>
            <CanonMenuCell
              @items={{rateLabels}}
              @selected={{this.rateIndex}}
              @labelledBy={{titleId}}
              @onChange={{this.pickRate}}
            />
          </CanonRow>
          <CanonHeading @text="Timecode A" />
          <TimecodeField
            @value={{startA}}
            @dropFrame={{this.rate.drop}}
            @label="Timecode A"
            @onChange={{this.typeA}}
          />
          {{#if this.noteA}}
            <CanonStatus
              class="tcc-note"
              @text={{this.noteA.text}}
              @tone={{this.noteA.tone}}
              @row={{true}}
            />
          {{/if}}
          <CanonHeading @text="Operation" />
          <CanonSegmented
            aria-label="Operation"
            @items={{operations}}
            @selected={{if this.subtracts 1 0}}
            @onChange={{this.pickOperation}}
          />
          <CanonHeading @text="Timecode B" />
          <TimecodeField
            @value={{startB}}
            @dropFrame={{this.rate.drop}}
            @label="Timecode B"
            @onChange={{this.typeB}}
          />
          {{#if this.noteB}}
            <CanonStatus
              class="tcc-note"
              @text={{this.noteB.text}}
              @tone={{this.noteB.tone}}
              @row={{true}}
            />
          {{/if}}
        </CanonRows>
      </:sidebar>
      <:main>
        <CanonRows @framed={{true}}>
          <CanonHeading @text="Result" />
          <CanonTiles @items={{this.tiles}} />
          <CanonButton
            @text="Copy"
            @icon={{component Icon svg=copy}}
            @iconStyle="oversized"
            @kind="primary"
            @disabled={{if this.result false true}}
            @flashesCopied={{true}}
            @onClick={{this.copyResult}}
          />
        </CanonRows>
      </:main>
    </CanonSplit>
  </template>
}
