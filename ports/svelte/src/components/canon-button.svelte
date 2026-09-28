<script lang="ts" module>
  export type CanonButtonKind = 'primary' | 'secondary' | 'cell' | 'segment';

  /** Seconds before a held button repeats, between repeats, and between repeats after ten. */
  export const repeatTiming = {
    delay: 0.4,
    interval: 0.09,
    fast: 0.04,
  } as const;
  export const flashSeconds = 1.5;
</script>

<script lang="ts">
  import { onDestroy, type Snippet } from 'svelte';
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLButtonAttributes } from 'svelte/elements';
  import { press } from '../lib/press.ts';
  import { check, iconSnippet } from '../lib/control-icons.ts';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-button.css';

  interface Props extends HTMLButtonAttributes {
    /** The title. Empty shows the icon alone. */
    text?: string;
    /** Rendered as the symbol; the consumer supplies it (lucide in the web app). */
    icon?: Snippet;
    /**
     * inline: small, beside the title. oversized: large and faint behind the
     * title, turned, cut off by the trailing and bottom edges. Keep it rare.
     */
    iconStyle?: 'inline' | 'oversized';
    /**
     * primary: the tool's main verb, fills its container. secondary: fills
     * its container. cell: content width, the enclosing grid or flush row
     * draws the lines. segment: a cell that shows `selected`.
     */
    kind?: CanonButtonKind;
    selected?: boolean;
    disabled?: boolean;
    /** Accessible name when the title is empty or dropped. */
    label?: string;
    onClick?: () => void;
    /** Holding the button runs onClick again and again; a tap runs it once. */
    repeats?: boolean;
    /** Shows Copied with a check for 1.5 s after each click. */
    flashesCopied?: boolean;
  }

  let {
    text: title = '',
    icon: givenIcon,
    iconStyle,
    kind = 'secondary',
    selected,
    disabled,
    label: givenLabel,
    onClick,
    repeats,
    flashesCopied,
    class: className,
    onclick,
    ...rest
  }: Props = $props();

  const Check = iconSnippet(check);

  let flashing = $state(false);
  let flashTimer: number | undefined;
  let holdTimer: number | undefined;
  let held = false;
  let didRepeat = false;

  const text = $derived(flashing ? 'Copied' : title);
  const icon = $derived(flashing ? Check : givenIcon);
  const oversized = $derived(iconStyle === 'oversized' && icon !== undefined);
  const filled = $derived(
    kind === 'primary' ||
      (selected === true && (kind === 'segment' || kind === 'secondary')),
  );
  // a grid drops the title of a filling button with a symbol when it does not fit
  const fits = $derived(
    (kind === 'primary' || kind === 'secondary') &&
      text !== '' &&
      icon !== undefined &&
      !oversized,
  );
  const label = $derived(
    icon === undefined ? undefined : (givenLabel ?? (text || undefined)),
  );

  function click(event: MouseEvent & { currentTarget: HTMLButtonElement }) {
    onclick?.(event);
    if (didRepeat) {
      didRepeat = false;
      return;
    }
    onClick?.();
    if (flashesCopied) flash();
  }

  function flash() {
    flashing = true;
    window.clearTimeout(flashTimer);
    flashTimer = window.setTimeout(() => {
      flashing = false;
    }, flashSeconds * 1000);
  }

  function schedule(seconds: number, count: number) {
    window.clearTimeout(holdTimer);
    holdTimer = window.setTimeout(() => {
      if (!held || disabled) return;
      didRepeat = true;
      onClick?.();
      schedule(
        count < 10 ? repeatTiming.interval : repeatTiming.fast,
        count + 1,
      );
    }, seconds * 1000);
  }

  const repeat: Attachment<HTMLButtonElement> = (button) => {
    const hold = (event: PointerEvent) => {
      if (!repeats || event.button !== 0) return;
      held = true;
      didRepeat = false;
      schedule(repeatTiming.delay, 0);
    };
    const letGo = () => {
      held = false;
      window.clearTimeout(holdTimer);
    };
    const ends = ['pointerup', 'pointerleave', 'pointercancel'] as const;
    button.addEventListener('pointerdown', hold);
    ends.forEach((type) => button.addEventListener(type, letGo));
    return () => {
      letGo();
      button.removeEventListener('pointerdown', hold);
      ends.forEach((type) => button.removeEventListener(type, letGo));
    };
  };

  onDestroy(() => {
    clearTimeout(flashTimer);
    clearTimeout(holdTimer);
  });
</script>

<button
  type="button"
  class={[
    'canon-button',
    `canon-button--${kind}`,
    filled && 'canon-button--filled',
    icon && 'canon-button--has-icon',
    oversized && 'canon-button--oversized',
    !text && 'canon-button--symbol',
    className,
  ]}
  data-canon-fit={fits ? '' : undefined}
  {disabled}
  aria-label={label}
  onclick={click}
  {@attach press}
  {@attach repeat}
  {...rest}
>
  {#if icon}
    <span
      class={oversized ? 'canon-button-watermark' : 'canon-button-icon'}
      aria-hidden="true">{@render icon()}</span
    >
  {/if}
  {#if text}
    <span class="canon-button-title">{text}</span>
  {/if}
</button>
