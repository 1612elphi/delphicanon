<script lang="ts" module>
  /** Seconds typing must pause before `onChange`. */
  export const typingDelay = 0.4;
</script>

<script lang="ts">
  import { onDestroy } from 'svelte';
  import type { HTMLAttributes } from 'svelte/elements';
  import { Clipboard, iconSnippet, trash } from '../lib/control-icons.ts';
  import CanonButton from './canon-button.svelte';
  import CanonGrid from './canon-grid.svelte';
  import CanonTextArea from './canon-text-area.svelte';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-text-input.css';

  interface Props extends Omit<HTMLAttributes<HTMLDivElement>, 'onchange'> {
    /** Starting text; later changes to the prop are not followed. */
    value?: string;
    placeholder?: string;
    /** Height of the text area in px; default 128. */
    height?: number;
    /** Accessible name of the text area; default Input. */
    label?: string;
    /** Typing arrives once it pauses; Paste and Clear arrive at once. */
    onChange?: (text: string) => void;
  }

  let {
    value,
    placeholder,
    height,
    label,
    onChange,
    class: className,
    ...rest
  }: Props = $props();

  const Trash = iconSnippet(trash);

  // svelte-ignore state_referenced_locally
  let text = $state(value ?? '');
  let destroyed = false;
  let timer: number | undefined;

  function typed(next: string) {
    text = next;
    window.clearTimeout(timer);
    timer = window.setTimeout(() => onChange?.(text), typingDelay * 1000);
  }

  /** Text set from code reaches `onChange` at once. */
  function setText(next: string) {
    window.clearTimeout(timer);
    text = next;
    onChange?.(next);
  }

  async function paste() {
    try {
      const pasted = await navigator.clipboard.readText();
      if (!destroyed) setText(pasted);
    } catch {
      return;
    }
  }

  const clear = () => setText('');

  onDestroy(() => {
    destroyed = true;
    clearTimeout(timer);
  });
</script>

<!-- @component The input block of a text tool: a text area with Paste and Clear under it. -->
<div class={['canon-text-input', className]} {...rest}>
  <CanonTextArea
    value={text}
    placeholder={placeholder || 'Type or paste'}
    height={height || 128}
    onChange={typed}
    aria-label={label || 'Input'}
  />
  <CanonGrid>
    <CanonButton text="Paste" icon={Clipboard} onClick={paste} />
    <CanonButton text="Clear" icon={Trash} disabled={!text} onClick={clear} />
  </CanonGrid>
</div>
