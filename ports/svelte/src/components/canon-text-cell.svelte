<script lang="ts">
  import type { HTMLInputAttributes } from 'svelte/elements';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-text-cell.css';

  interface Props extends Omit<HTMLInputAttributes, 'type' | 'value'> {
    value?: string;
    placeholder?: string;
    /** Called on every edit. */
    onChange?: (value: string) => void;
  }

  let {
    value,
    placeholder,
    onChange,
    class: className,
    oninput,
    onkeydown,
    ...rest
  }: Props = $props();

  function input(event: Event & { currentTarget: HTMLInputElement }) {
    oninput?.(event);
    onChange?.(event.currentTarget.value);
  }

  function key(event: KeyboardEvent & { currentTarget: HTMLInputElement }) {
    onkeydown?.(event);
    if (event.key === 'Enter') event.currentTarget.blur();
  }
</script>

<!-- @component Text field that meets its row's edges. -->
<input
  type="text"
  class={['canon-text-cell', className]}
  {value}
  {placeholder}
  enterkeyhint="done"
  oninput={input}
  onkeydown={key}
  {...rest}
/>
