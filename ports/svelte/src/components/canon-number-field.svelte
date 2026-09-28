<script lang="ts">
  import type { HTMLAttributes } from 'svelte/elements';
  import CanonStepper from './canon-stepper.svelte';
  import { clamp, parseInteger } from '@canon/lib/number.ts';
  import '@canon/styles/tokens.css';

  interface Props extends Omit<HTMLAttributes<HTMLDivElement>, 'children'> {
    value: number;
    min?: number;
    max?: number;
    step?: number;
    /** Muted, after the number. */
    unit?: string;
    /** Id of the element that names the field, such as a row title. */
    labelledBy?: string;
    label?: string;
    disabled?: boolean;
    onChange?: (value: number) => void;
  }

  let {
    value: given,
    min = 0,
    max = Number.MAX_SAFE_INTEGER,
    step,
    unit,
    labelledBy,
    label,
    disabled,
    onChange,
    class: className,
    ...rest
  }: Props = $props();

  // a change holds until the value prop changes
  let held = $state<{ value: number; over: number }>();
  let draft = $state<string>();

  const value = $derived(
    clamp(held && held.over === given ? held.value : given, min, max),
  );
  const text = $derived(draft ?? String(value));

  function commit(next: number) {
    if (next === value) return;
    held = { value: next, over: given };
    onChange?.(next);
  }

  function nudge(direction: -1 | 1) {
    draft = undefined;
    commit(clamp(value + direction * (step ?? 1), min, max));
  }

  function typed(event: Event & { currentTarget: HTMLInputElement }) {
    draft = event.currentTarget.value;
    const next = parseInteger(draft);
    if (next !== undefined && next >= min && next <= max) commit(next);
  }

  function key(event: KeyboardEvent & { currentTarget: HTMLInputElement }) {
    if (event.key === 'Enter') event.currentTarget.blur();
    if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown') return;
    event.preventDefault();
    nudge(event.key === 'ArrowUp' ? 1 : -1);
  }
</script>

<!-- @component Integer with step buttons either side. Arrow keys step too. -->
<CanonStepper
  class={['canon-number-field', className]}
  onStep={nudge}
  {disabled}
  {...rest}
>
  <span class="canon-stepper-value">
    <input
      type="text"
      class="canon-stepper-field"
      role="spinbutton"
      aria-valuenow={value}
      aria-valuemin={min}
      aria-valuemax={max}
      inputmode={min < 0 ? 'text' : 'numeric'}
      enterkeyhint="done"
      aria-labelledby={labelledBy}
      aria-label={label}
      value={text}
      {disabled}
      oninput={typed}
      onkeydown={key}
      onblur={() => (draft = undefined)}
    />
    {#if unit}<span class="canon-stepper-unit">{unit}</span>{/if}
  </span>
</CanonStepper>
