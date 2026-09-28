<script lang="ts">
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLAttributes } from 'svelte/elements';
  import { changedFromEnd, leadingNumber } from '@canon/lib/figure.ts';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-figure.css';

  interface Props extends Omit<HTMLAttributes<HTMLDivElement>, 'children'> {
    text: string;
    /** Set smaller after the figure. */
    unit?: string;
    /** Font size in px; default 40. */
    size?: number;
    /** CSS colour; default the primary colour. A change fades. */
    colour?: string;
    /** Outline and soft shadow in this CSS colour, for a figure over a picture. */
    halo?: string;
    /** False shows a new text without rolling. */
    animated?: boolean;
  }

  let {
    text,
    unit,
    size = 40,
    colour,
    halo,
    animated,
    class: className,
    ...rest
  }: Props = $props();

  const rollMs = 350;
  const easing = 'cubic-bezier(0.2, 0.9, 0.3, 1)';
  let previous: string | undefined;

  const style = $derived.by(() => {
    const parts = [`--canon-figure-size: ${size}px`];
    if (colour) parts.push(`--canon-figure-colour: ${colour}`);
    if (halo) {
      const edge = `0 0 1px ${halo}`;
      parts.push(
        `text-shadow: ${edge}, ${edge}, ${edge}, ${edge}, 0 3px 5px ${halo}`,
      );
    }
    return parts.join('; ');
  });

  const still = () =>
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /** Rebuilds the characters; changed ones roll in the direction the number moved. */
  function roll(text: string, animated: boolean): Attachment<HTMLElement> {
    return (element) => {
      const before = previous;
      previous = text;
      element.replaceChildren(
        ...[...text].map((char) => {
          const span = document.createElement('span');
          span.className = 'canon-figure-char';
          span.textContent = char;
          return span;
        }),
      );
      if (before === undefined || before === text || !animated || still())
        return;
      // up rolls new characters in from below
      const up = leadingNumber(text) >= leadingNumber(before) ? 1 : -1;
      const spans = [...element.children] as HTMLElement[];
      for (const { index, old } of changedFromEnd(before, text)) {
        const span = spans[index]!;
        span.animate(
          [
            {
              transform: `translateY(${up * 60}%)`,
              opacity: 0,
              filter: 'blur(2px)',
            },
            { transform: 'none', opacity: 1, filter: 'none' },
          ],
          { duration: rollMs, easing },
        );
        if (old === undefined) continue;
        const ghost = document.createElement('span');
        ghost.className = 'canon-figure-ghost';
        ghost.textContent = old;
        span.append(ghost);
        ghost
          .animate(
            [
              { transform: 'none', opacity: 1, filter: 'none' },
              {
                transform: `translateY(${-up * 60}%)`,
                opacity: 0,
                filter: 'blur(2px)',
              },
            ],
            { duration: rollMs, easing, fill: 'forwards' },
          )
          .finished.then(
            () => ghost.remove(),
            () => ghost.remove(),
          );
      }
    };
  }
</script>

<!-- @component A calculated figure whose changed characters roll. -->
<div class={['canon-figure', className]} {style} {...rest}>
  <span class="canon-figure-said">{text}{unit}</span>
  <span
    class="canon-figure-text"
    aria-hidden="true"
    {@attach roll(text, animated !== false)}
  ></span>
  {#if unit}
    <span class="canon-figure-unit" aria-hidden="true">{unit}</span>
  {/if}
</div>
