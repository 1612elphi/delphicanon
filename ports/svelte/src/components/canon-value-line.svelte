<script lang="ts" module>
  export type CanonValueLineLayout =
    'beside' | 'above' | 'wrapping' | 'numbered';

  const dash = '—';
  const shownBefore = new WeakMap<HTMLElement, string>();
</script>

<script lang="ts">
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLButtonAttributes } from 'svelte/elements';
  import { copy as copyIcon } from '../lib/control-icons.ts';
  import { press } from '../lib/press.ts';
  import { canonToast } from '../lib/toast-store.svelte.ts';
  import CanonIcon from './canon-icon.svelte';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-value-line.css';

  interface Props extends HTMLButtonAttributes {
    label: string;
    /** Null or undefined shows a dash and turns copying off. */
    value?: string | null;
    /**
     * beside: the label in a column `labelWidth` wide, the value on one line.
     * above: the label over the value. wrapping: the label as wide as it is,
     * the value wrapping by character. numbered: a list index as the label.
     */
    layout?: CanonValueLineLayout;
    /** Width of the label column in px for `beside`; fit it to the longest label among sibling lines. */
    labelWidth?: number;
    /** For `numbered`: a long value wraps by character instead of being cut off. */
    wraps?: boolean;
    /** Seconds after a change before the new value fades in; unset changes it at once. */
    fadeDelay?: number;
    /** Marks the chosen line of a list. */
    lit?: boolean;
    /** CSS colour for each character of the value; unset sets the value in one colour. */
    tint?: (character: string) => string;
    disabled?: boolean;
  }

  let {
    label,
    value,
    layout = 'beside',
    labelWidth,
    wraps,
    fadeDelay,
    lit,
    tint,
    disabled,
    class: className,
    onclick,
    ...rest
  }: Props = $props();

  const shown = $derived(value ?? dash);
  const characters = $derived(tint ? [...shown] : undefined);
  const ariaLabel = $derived(
    layout === 'numbered' ? shown : `${label} ${shown}`,
  );

  function copy(event: MouseEvent & { currentTarget: HTMLButtonElement }) {
    onclick?.(event);
    void canonToast.copy(shown);
  }

  /** The old value stays for the delay, then crossfades to the new one. */
  function fade(
    text: string,
    delay: number | undefined,
  ): Attachment<HTMLElement> {
    return (element) => {
      const before = shownBefore.get(element);
      shownBefore.set(element, text);
      if (delay === undefined || before === undefined || before === text)
        return;
      if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
      const ghost = document.createElement('span');
      ghost.className = 'canon-value-line-value canon-value-line-ghost';
      ghost.textContent = before;
      ghost.setAttribute('aria-hidden', 'true');
      Object.assign(ghost.style, {
        insetInlineStart: `${element.offsetLeft}px`,
        insetBlockStart: `${element.offsetTop}px`,
        inlineSize: `${element.offsetWidth}px`,
      });
      element.after(ghost);
      const duration =
        parseFloat(
          getComputedStyle(element).getPropertyValue('--canon-value-line-fade'),
        ) || 250;
      const timing = { duration, delay: delay * 1000 };
      element.animate({ opacity: [0, 1] }, { ...timing, fill: 'backwards' });
      ghost
        .animate({ opacity: [1, 0] }, { ...timing, fill: 'forwards' })
        .finished.catch(() => undefined)
        .finally(() => ghost.remove());
    };
  }
</script>

<!-- @component A name and a value in a flush cell; a tap copies the value and confirms with the toast. -->
<button
  type="button"
  class={[
    'canon-value-line',
    `canon-value-line--${layout}`,
    wraps && 'canon-value-line--wraps',
    lit && 'canon-value-line--lit',
    className,
  ]}
  style="--canon-value-line-label: {labelWidth ?? 48}px"
  aria-label={ariaLabel}
  aria-current={lit ? 'true' : undefined}
  disabled={disabled || value == null}
  onclick={copy}
  {@attach press}
  {...rest}
>
  <span class="canon-value-line-label">{label}</span>
  <span class="canon-value-line-value" {@attach fade(shown, fadeDelay)}
    >{#if characters && tint}{#each characters as character, i (i)}<span
          style="color: {tint(character)}">{character}</span
        >{/each}{:else}{shown}{/if}</span
  >
  <span class="canon-value-line-glyph" aria-hidden="true"
    ><CanonIcon svg={copyIcon} /></span
  >
</button>
