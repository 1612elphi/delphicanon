<script lang="ts">
  import type { HTMLAttributes } from 'svelte/elements';
  import CanonFigure from './canon-figure.svelte';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-dimension-line.css';

  interface Props extends Omit<HTMLAttributes<HTMLSpanElement>, 'children'> {
    pixels: number;
    /** Turned a quarter, reading upwards, beside the leading side of what it measures. */
    down?: boolean;
    /** Muted rule and ticks, no figure: an empty picture keeps a loaded one's frame without stale sizes. */
    blank?: boolean;
  }

  let { pixels, down, blank, class: className, ...rest }: Props = $props();
</script>

<!--
  @component
  A measured span: a rule with end ticks along its bottom edge, the pixel
  figure centred above it. Placed by the consumer with inset and size
  properties (`dimensionLines` in `lib/dimension-line.ts`), before the turn.
-->
<span
  class={[
    'canon-dimension-line',
    down && 'canon-dimension-line--down',
    blank && 'canon-dimension-line--blank',
    className,
  ]}
  aria-hidden="true"
  {...rest}
>
  {#if !blank}
    <CanonFigure
      class="canon-dimension-line-figure"
      text={String(pixels)}
      unit="px"
      size={17}
      halo="var(--canon-muted)"
    />
  {/if}
</span>
