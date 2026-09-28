<script lang="ts">
  import type { HTMLInputAttributes } from 'svelte/elements';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-switch.css';

  interface Props extends Omit<HTMLInputAttributes, 'type' | 'checked'> {
    on?: boolean;
    disabled?: boolean;
    onChange?: (on: boolean) => void;
  }

  let {
    on: given,
    disabled,
    onChange,
    class: className,
    onchange,
    ...rest
  }: Props = $props();

  // a flip holds until the on prop changes
  let flipped = $state<{ on: boolean; over: boolean | undefined }>();

  const on = $derived(
    flipped && flipped.over === given ? flipped.on : (given ?? false),
  );

  function change(event: Event & { currentTarget: HTMLInputElement }) {
    onchange?.(event);
    const next = event.currentTarget.checked;
    flipped = { on: next, over: given };
    onChange?.(next);
  }
</script>

<!-- @component An on/off switch: a native checkbox with the switch role. -->
<input
  type="checkbox"
  role="switch"
  class={['canon-switch', className]}
  checked={on}
  aria-checked={on ? 'true' : 'false'}
  {disabled}
  onchange={change}
  {...rest}
/>
