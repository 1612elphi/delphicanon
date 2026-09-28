<script lang="ts">
  import type { HTMLAttributes } from 'svelte/elements';
  import CanonIcon from './canon-icon.svelte';
  import CanonMenuCell from './canon-menu-cell.svelte';
  import { arrowRight } from '../lib/control-icons.ts';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-from-to.css';

  interface Props extends Omit<HTMLAttributes<HTMLDivElement>, 'children'> {
    items: string[];
    from?: number;
    to?: number;
    /** Accessible names of the two menus; default From and To. */
    fromLabel?: string;
    toLabel?: string;
    disabled?: boolean;
    onFromChange?: (index: number) => void;
    onToChange?: (index: number) => void;
  }

  let {
    items,
    from,
    to,
    fromLabel,
    toLabel,
    disabled,
    onFromChange,
    onToChange,
    class: className,
    ...rest
  }: Props = $props();
</script>

<!-- @component Two menus of the same choices with an arrow between: a conversion from one to the other. -->
<div class={['canon-from-to', className]} role="group" {...rest}>
  <CanonMenuCell
    {items}
    selected={from}
    label={fromLabel || 'From'}
    {disabled}
    onChange={onFromChange}
  />
  <span class="canon-from-to-arrow" aria-hidden="true"
    ><CanonIcon svg={arrowRight} /></span
  >
  <CanonMenuCell
    {items}
    selected={to}
    label={toLabel || 'To'}
    {disabled}
    onChange={onToChange}
  />
</div>
