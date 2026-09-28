<script lang="ts" module>
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

  /** Height of the row under the strip in `below`. */
  export const readoutRow = 44;

  /** The band's height for a strip of a given height, in `below`. */
  export function readoutBandHeight(strip: number) {
    return strip + readoutRow;
  }
</script>

<script lang="ts">
  import type { Snippet } from 'svelte';
  import type { HTMLAttributes } from 'svelte/elements';
  import CanonLamps, {
    transportLamps,
    type CanonLamp,
  } from './canon-lamps.svelte';
  import CanonTimecode from './canon-timecode.svelte';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-readout-band.css';

  interface Props extends Omit<HTMLAttributes<HTMLDivElement>, 'children'> {
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
    /** The picture of the whole file: a waveform, a filmstrip. Gets the playhead. */
    children?: Snippet<[playhead: number | null | undefined]>;
  }

  let {
    transport,
    idle,
    readout = 'over',
    lamps,
    format,
    children,
    class: className,
    ...rest
  }: Props = $props();

  const lit = $derived.by(() => {
    const { playing, paused, looping, recording } = transport;
    const on: CanonLamp[] = [];
    if (playing) on.push('play');
    if (paused) on.push('pause');
    if (looping) on.push('loop');
    if (recording) on.push('record');
    return on;
  });
  const flashes = $derived({ loop: transport.loops ?? 0 });
  const label = $derived(
    transport.playhead === undefined || transport.playhead === null
      ? 'Length'
      : 'Position',
  );
</script>

<!-- @component A strip of the whole file under a counter and transport lamps: the banner of a media tool. -->
<div
  class={['canon-readout-band', `canon-readout-band--${readout}`, className]}
  {...rest}
>
  <div class="canon-readout-band-strip">
    {@render children?.(transport.playhead)}
  </div>
  <div class="canon-readout-band-readout">
    <CanonLamps
      lamps={lamps?.length ? lamps : transportLamps}
      {lit}
      {flashes}
    />
    <CanonTimecode
      seconds={transport.playhead ?? idle}
      {format}
      size={readout === 'over' ? 44 : 30}
      {label}
    />
  </div>
</div>
