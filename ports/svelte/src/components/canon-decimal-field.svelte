<script lang="ts" module>
  /** Typing commits after this pause, or when the field loses focus. */
  export const typingPauseMs = 600;
</script>

<script lang="ts">
  import { onDestroy } from 'svelte';
  import type { HTMLAttributes } from 'svelte/elements';
  import CanonStepper from './canon-stepper.svelte';
  import {
    formatDecimal,
    parseDecimal,
    roundDecimal,
  } from '@canon/lib/number.ts';
  import '@canon/styles/tokens.css';

  interface Props extends Omit<HTMLAttributes<HTMLDivElement>, 'children'> {
    value: number;
    /** Default 0, or no lower bound when `signed`. */
    min?: number;
    max?: number;
    /** Default "s". */
    unit?: string;
    /** Default 0.1. */
    step?: number;
    /** Places kept; default 3. */
    decimals?: number;
    /** Gives a touch keyboard a minus key; the decimal pad has none. */
    signed?: boolean;
    labelledBy?: string;
    label?: string;
    disabled?: boolean;
    onChange?: (value: number) => void;
  }

  let {
    value: given,
    min: givenMin,
    max = Infinity,
    unit = 's',
    step = 0.1,
    decimals = 3,
    signed,
    labelledBy,
    label,
    disabled,
    onChange,
    class: className,
    ...rest
  }: Props = $props();

  let held = $state<{ value: number; over: number }>();
  let draft = $state<string>();
  let typing: number | undefined;

  const min = $derived(givenMin ?? (signed ? -Infinity : 0));
  const value = $derived(held && held.over === given ? held.value : given);
  const text = $derived(draft ?? formatDecimal(value, decimals));

  function apply(raw: number) {
    const next = roundDecimal(raw, decimals, min, max);
    if (next === value) return;
    held = { value: next, over: given };
    onChange?.(next);
  }

  function stepBy(direction: -1 | 1) {
    draft = undefined;
    apply(value + direction * step);
  }

  function commit() {
    window.clearTimeout(typing);
    const typed = draft === undefined ? undefined : parseDecimal(draft);
    if (typed !== undefined) apply(typed);
  }

  function typed(event: Event & { currentTarget: HTMLInputElement }) {
    draft = event.currentTarget.value;
    window.clearTimeout(typing);
    typing = window.setTimeout(commit, typingPauseMs);
  }

  function key(event: KeyboardEvent & { currentTarget: HTMLInputElement }) {
    if (event.key === 'Enter') event.currentTarget.blur();
    if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown') return;
    event.preventDefault();
    commit();
    stepBy(event.key === 'ArrowUp' ? 1 : -1);
  }

  function leave() {
    commit();
    draft = undefined;
  }

  onDestroy(() => clearTimeout(typing));
</script>

<!-- @component A decimal number with step buttons and a unit; seconds by default. -->
<CanonStepper
  class={['canon-decimal-field', className]}
  onStep={stepBy}
  {disabled}
  {...rest}
>
  <span class="canon-stepper-value">
    <input
      type="text"
      class="canon-stepper-field canon-decimal-field-input"
      role="spinbutton"
      aria-valuenow={value}
      aria-valuetext="{text} {unit}"
      inputmode={signed ? 'text' : 'decimal'}
      enterkeyhint="done"
      aria-labelledby={labelledBy}
      aria-label={label}
      value={text}
      {disabled}
      oninput={typed}
      onkeydown={key}
      onblur={leave}
    />
    <span class="canon-stepper-unit">{unit}</span>
  </span>
</CanonStepper>
