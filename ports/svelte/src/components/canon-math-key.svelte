<script lang="ts" module>
  /** Travel in px that turns a press into a drag. */
  export const slop = 10;
</script>

<script lang="ts">
  import { onDestroy, type Snippet } from 'svelte';
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLButtonAttributes } from 'svelte/elements';
  import { press } from '../lib/press.ts';
  import { chevronUp } from '../lib/control-icons.ts';
  import { repeatTiming } from './canon-button.svelte';
  import CanonIcon from './canon-icon.svelte';
  import CanonMathView from './canon-math-view.svelte';
  import type { Key } from '@canon/lib/math/expression.ts';
  import {
    familyOf,
    keyHeights,
    label as labelFor,
    labelShare,
    spoken,
    type Family,
  } from '@canon/lib/math/keypad.ts';
  import { canvasMetrics } from '@canon/lib/math/measure.ts';
  import type { Box } from '@canon/lib/math/typeset.ts';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-math-key.css';

  interface Props extends HTMLButtonAttributes {
    /** The key typed; gives the label, the family and the spoken name. */
    key?: Key;
    /** The letter the derivative key shows; default x. */
    variable?: string;
    /** Label size in px before `scale`; default 24, the regular key's. */
    size?: number;
    scale?: number;
    /** A label set elsewhere, instead of the key's. */
    face?: Box;
    family?: Family;
    /** Accessible name; default the key's spoken name. */
    label?: string;
    /** Marks a key that opens a submenu with a chevron. */
    menu?: boolean;
    /** Holding repeats the tap, as delete does. */
    repeats?: boolean;
    onClick?: () => void;
    children?: Snippet;
  }

  let {
    key,
    variable = 'x',
    size,
    scale = 1,
    face: givenFace,
    family: givenFamily,
    label: givenLabel,
    menu,
    repeats,
    onClick,
    children,
    class: className,
    onclick,
    ...rest
  }: Props = $props();

  let start: { x: number; y: number } | undefined;
  let moved = false;
  let held = false;
  let didRepeat = false;
  let timer: number | undefined;

  const family = $derived<Family>(
    givenFamily ?? (key ? familyOf(key) : 'digit'),
  );
  const face = $derived.by((): Box | undefined => {
    if (givenFace) return givenFace;
    if (!key) return undefined;
    const base = size ?? Math.round(keyHeights.regular * labelShare);
    return labelFor(key, variable, base * scale, canvasMetrics);
  });
  const label = $derived(
    givenLabel ?? (key ? spoken(key, variable) : undefined),
  );

  function click(event: MouseEvent & { currentTarget: HTMLButtonElement }) {
    onclick?.(event);
    if (moved || didRepeat) {
      didRepeat = false;
      return;
    }
    onClick?.();
  }

  function letGo() {
    held = false;
    window.clearTimeout(timer);
  }

  function schedule(seconds: number, count: number) {
    window.clearTimeout(timer);
    timer = window.setTimeout(() => {
      if (!held) return;
      didRepeat = true;
      onClick?.();
      schedule(
        count < 10 ? repeatTiming.interval : repeatTiming.fast,
        count + 1,
      );
    }, seconds * 1000);
  }

  const stroke: Attachment<HTMLButtonElement> = (button) => {
    const down = (event: PointerEvent) => {
      start = { x: event.clientX, y: event.clientY };
      moved = false;
      didRepeat = false;
      if (!repeats || event.button !== 0) return;
      held = true;
      schedule(repeatTiming.delay, 0);
    };
    const move = (event: PointerEvent) => {
      if (!start || moved) return;
      const travel = Math.hypot(
        event.clientX - start.x,
        event.clientY - start.y,
      );
      if (travel > slop && !didRepeat) {
        moved = true;
        letGo();
      }
    };
    const ends = ['pointerup', 'pointercancel', 'lostpointercapture'] as const;
    button.addEventListener('pointerdown', down);
    button.addEventListener('pointermove', move);
    ends.forEach((type) => button.addEventListener(type, letGo));
    return () => {
      letGo();
      button.removeEventListener('pointerdown', down);
      button.removeEventListener('pointermove', move);
      ends.forEach((type) => button.removeEventListener(type, letGo));
    };
  };

  onDestroy(() => window.clearTimeout(timer));
</script>

<!--
  @component
  One key: a flush cell in its family's colours with one label, set large
  and centred (CanonMathKeyView). A tap does one thing; a drag past the slop
  does nothing. Outside the keypad it is the insert cell
  (`CanonMathKeypad.cell`).
-->
<button
  type="button"
  class={['canon-math-key', `canon-math-key--${family}`, className]}
  aria-label={label}
  aria-haspopup={menu ? 'true' : undefined}
  onclick={click}
  {@attach press}
  {@attach stroke}
  {...rest}
>
  <span class="canon-math-key-face">
    {#if children}
      {@render children()}
    {:else if face}
      <CanonMathView box={face} mono aria-hidden="true" />
    {/if}
    {#if menu}<span class="canon-math-key-chevron"
        ><CanonIcon svg={chevronUp} /></span
      >{/if}
  </span>
</button>
