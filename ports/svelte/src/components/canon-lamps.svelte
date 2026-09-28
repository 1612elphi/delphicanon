<script lang="ts" module>
  export type CanonLamp = 'play' | 'pause' | 'loop' | 'record';

  export const transportLamps: CanonLamp[] = ['play', 'pause', 'loop'];

  /** Milliseconds a lamp stays unlit when it blinks. */
  export const lampBlinkMs = 120;
</script>

<script lang="ts">
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLAttributes } from 'svelte/elements';
  import { circleDot, pause, play, repeat } from '../lib/control-icons.ts';
  import CanonIcon from './canon-icon.svelte';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-lamps.css';

  interface Props extends HTMLAttributes<HTMLSpanElement> {
    /** Which lamps; every one is always present. Default play, pause, loop. */
    lamps?: readonly CanonLamp[];
    lit?: readonly CanonLamp[];
    /** A count per lamp; each change turns that lamp off for a split second. */
    flashes?: Partial<Record<CanonLamp, number>>;
  }

  let { lamps, lit, flashes, class: className, ...rest }: Props = $props();

  const icons = { play, pause, loop: repeat, record: circleDot };

  function blink(count: number | undefined): Attachment<HTMLElement> {
    return (element) => {
      const last = element.dataset['flashes'];
      element.dataset['flashes'] = String(count ?? 0);
      if (last === undefined || last === String(count ?? 0)) return;
      element.classList.add('canon-lamps-lamp--blink');
      const timer = window.setTimeout(
        () => element.classList.remove('canon-lamps-lamp--blink'),
        lampBlinkMs,
      );
      return () => window.clearTimeout(timer);
    };
  }
</script>

<!--
  @component
  Transport lamps: every icon is always present, lit while its state holds.
  Record lights red.
-->
<span class={['canon-lamps', className]} aria-hidden="true" {...rest}>
  {#each lamps?.length ? lamps : transportLamps as lamp (lamp)}
    <span
      class={[
        'canon-lamps-lamp',
        `canon-lamps-lamp--${lamp}`,
        lit?.includes(lamp) && 'canon-lamps-lamp--lit',
      ]}
      {@attach blink(flashes?.[lamp])}><CanonIcon svg={icons[lamp]} /></span
    >
  {/each}
</span>
