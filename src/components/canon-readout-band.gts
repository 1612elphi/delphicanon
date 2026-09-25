import Component from '@glimmer/component';
import CanonLamps, { transportLamps, type CanonLamp } from './canon-lamps.gts';
import CanonTimecode from './canon-timecode.gts';
import '../styles/tokens.css';
import './canon-readout-band.css';

/** What a readout band shows of a player. */
export interface CanonTransport {
  playhead?: number | null;
  playing?: boolean;
  /** Parked at `playhead`. */
  paused?: boolean;
  /** Capturing, for a record lamp. */
  recording?: boolean;
  looping?: boolean;
  /** Count of wraps; a change blinks the loop lamp. */
  loops?: number;
}

export interface CanonReadoutBandSignature {
  Args: {
    transport: CanonTransport;
    /** Seconds the counter shows without a playhead; none shows hyphens. */
    idle?: number | null;
    /**
     * over: counter and lamps sit over the strip's bottom corners, a waveform
     * reads through them. below: they get a row of their own under the strip,
     * a filmstrip's frames stay clear.
     */
    readout?: 'over' | 'below';
    /** Which lamps the band has; every one is always present. */
    lamps?: readonly CanonLamp[];
    /** See CanonTimecode's `format`. */
    format?: (seconds: number) => string;
  };
  /** The picture of the whole file: a waveform, a filmstrip. Yields the playhead. */
  Blocks: { default: [playhead: number | null | undefined] };
  Element: HTMLDivElement;
}

/** Height of the row under the strip in `below`. */
export const readoutRow = 44;

/** The band's height for a strip of a given height, in `below`. */
export function readoutBandHeight(strip: number) {
  return strip + readoutRow;
}

/** A strip of the whole file under a counter and transport lamps: the banner of a media tool. */
export default class CanonReadoutBand extends Component<CanonReadoutBandSignature> {
  get readout() {
    return this.args.readout ?? 'over';
  }

  get lit(): CanonLamp[] {
    const { playing, paused, looping, recording } = this.args.transport;
    const lit: CanonLamp[] = [];
    if (playing) lit.push('play');
    if (paused) lit.push('pause');
    if (looping) lit.push('loop');
    if (recording) lit.push('record');
    return lit;
  }

  get flashes() {
    return { loop: this.args.transport.loops ?? 0 };
  }

  get seconds() {
    return this.args.transport.playhead ?? this.args.idle;
  }

  get label() {
    const { playhead } = this.args.transport;
    return playhead === undefined || playhead === null ? 'Length' : 'Position';
  }

  <template>
    <div
      class="canon-readout-band canon-readout-band--{{this.readout}}"
      ...attributes
    >
      <div class="canon-readout-band-strip">{{yield @transport.playhead}}</div>
      <div class="canon-readout-band-readout">
        <CanonLamps
          @lamps={{if @lamps @lamps transportLamps}}
          @lit={{this.lit}}
          @flashes={{this.flashes}}
        />
        <CanonTimecode
          @seconds={{this.seconds}}
          @format={{@format}}
          @size={{if (isOver this.readout) 44 30}}
          @label={{this.label}}
        />
      </div>
    </div>
  </template>
}

function isOver(readout: string) {
  return readout === 'over';
}
