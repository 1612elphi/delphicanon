<script lang="ts">
  import type { HTMLAttributes } from 'svelte/elements';
  import {
    formatColour,
    hex as hexOf,
    parseHex,
    type ColourFormat,
    type Rgb,
  } from '@canon/lib/colour.ts';
  import { press } from '../lib/press.ts';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-colour-well.css';

  interface Props extends Omit<HTMLAttributes<HTMLDivElement>, 'onChange'> {
    /** Caption over the hex, and the swatch's accessible name. */
    label?: string;
    colour: Rgb;
    /** The app's primary colour format, echoed under the hex unless it is hex. */
    format?: ColourFormat;
    onChange?: (colour: Rgb) => void;
  }

  let {
    label,
    colour,
    format,
    onChange,
    class: className,
    ...rest
  }: Props = $props();

  const hex = $derived(hexOf(colour));
  const digits = $derived(hex.slice(1));
  const echo = $derived(
    format && format !== 'hex' ? formatColour(colour, format) : undefined,
  );

  function picked(event: Event & { currentTarget: HTMLInputElement }) {
    const picked = parseHex(event.currentTarget.value);
    if (picked) onChange?.(picked);
  }

  function typed(event: Event & { currentTarget: HTMLInputElement }) {
    const field = event.currentTarget;
    const typedDigits = field.value.replace(/[^\da-f]/gi, '');
    const next = typedDigits.length === 6 ? parseHex(typedDigits) : undefined;
    if (next && hexOf(next) !== hex) onChange?.(next);
    field.value = next ? hexOf(next).slice(1) : digits;
  }

  function done(event: KeyboardEvent & { currentTarget: HTMLInputElement }) {
    if (event.key === 'Enter') event.currentTarget.blur();
  }
</script>

<!-- @component Swatch cell that opens the system picker, beside a hex field. -->
<div class={['canon-colour-well', className]} {...rest}>
  <div
    class="canon-colour-well-swatch"
    style="background: {hex}"
    {@attach press}
  >
    <input
      type="color"
      value={hex}
      aria-label={label ? label : 'Colour'}
      oninput={picked}
    />
  </div>
  <div class="canon-colour-well-cell">
    {#if label}
      <span class="canon-colour-well-label">{label}</span>
    {/if}
    <span class="canon-colour-well-field">
      <span class="canon-colour-well-hash" aria-hidden="true">#</span>
      <input
        type="text"
        value={digits}
        placeholder="000000"
        maxlength="7"
        spellcheck="false"
        autocomplete="off"
        autocapitalize="off"
        aria-label={label ? label : 'Hex'}
        onchange={typed}
        onkeydown={done}
      />
    </span>
    {#if echo}
      <span class="canon-colour-well-echo">{echo}</span>
    {/if}
  </div>
</div>
