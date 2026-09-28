<script lang="ts">
  import type { HTMLAttributes } from 'svelte/elements';
  import {
    formatColour,
    hex,
    type ColourFormat,
    type Rgb,
  } from '@canon/lib/colour.ts';
  import { press } from '../lib/press.ts';
  import { canonToast } from '../lib/toast-store.svelte.ts';
  import CanonSwatch from './canon-swatch.svelte';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-colour-strip.css';

  interface Props extends HTMLAttributes<HTMLDivElement> {
    colour: Rgb;
    /** Shows these colours as swatches instead, each copying its hex on a tap. */
    palette?: Rgb[];
    /** Nearest colour name for a hex. */
    nameOf?: (hex: string) => string;
    /** The value shown and copied; default hex. */
    format?: ColourFormat;
  }

  let {
    colour,
    palette,
    nameOf,
    format,
    class: className,
    ...rest
  }: Props = $props();

  const value = $derived(formatColour(colour, format ?? 'hex'));
  const name = $derived(nameOf?.(hex(colour)));
  const showsPalette = $derived((palette?.length ?? 0) > 0);

  const copy = () => void canonToast.copy(value);
</script>

<!--
  @component
  A strip along the bottom of a colour picture: swatch, nearest name, the
  colour in the primary format; a tap copies the value. Place it under the
  picture inside the same canvas.
-->
<div class={['canon-colour-strip', className]} {...rest}>
  {#if showsPalette}
    <div class="canon-colour-strip-palette">
      {#each palette as swatch, i (i)}
        <CanonSwatch colour={swatch} {nameOf} />
      {/each}
    </div>
  {:else}
    <button
      type="button"
      class="canon-colour-strip-single"
      aria-label="{name} {value}"
      onclick={copy}
      {@attach press}
    >
      <span class="canon-colour-strip-swatch" style="background: {hex(colour)}"
      ></span>
      <span class="canon-colour-strip-text">
        {#if name}
          <span class="canon-colour-strip-name">{name}</span>
        {/if}
        <span class="canon-colour-strip-value">{value}</span>
      </span>
    </button>
  {/if}
</div>
