<script lang="ts">
  import type { HTMLButtonAttributes } from 'svelte/elements';
  import { hex as hexOf, takesBlackInk, type Rgb } from '@canon/lib/colour.ts';
  import { press } from '../lib/press.ts';
  import { canonToast } from '../lib/toast-store.svelte.ts';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-swatch.css';

  interface Props extends HTMLButtonAttributes {
    colour: Rgb;
    /** Nearest colour name for a hex, read by assistive technology. */
    nameOf?: (hex: string) => string;
  }

  let { colour, nameOf, class: className, onclick, ...rest }: Props = $props();

  const hex = $derived(hexOf(colour));
  const label = $derived.by(() => {
    const name = nameOf?.(hex);
    return name ? `${name} ${hex}` : hex;
  });
  const style = $derived(
    `background: ${hex}; color: ${takesBlackInk(colour) ? 'black' : 'white'}`,
  );

  function copy(event: MouseEvent & { currentTarget: HTMLButtonElement }) {
    onclick?.(event);
    void canonToast.copy(hex);
  }
</script>

<!--
  @component
  One colour, its hex where it fits; a tap copies the hex. The swatch of a
  CanonColourStrip palette. Its width comes from the parent (a grid cell or
  a flex item that grows): it measures itself for the hex.
-->
<button
  type="button"
  class={['canon-swatch', className]}
  {style}
  aria-label={label}
  onclick={copy}
  {@attach press}
  {...rest}
  ><span class="canon-swatch-hex" aria-hidden="true">{hex}</span></button
>
