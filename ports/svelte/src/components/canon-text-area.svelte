<script lang="ts">
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLTextareaAttributes } from 'svelte/elements';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-text-area.css';

  interface Props extends Omit<HTMLTextareaAttributes, 'value'> {
    value?: string;
    placeholder?: string;
    /** Fixed height in px; default 200. The text scrolls inside it. */
    height?: number;
    /** Called for typed edits, not for a new `value`. */
    onChange?: (value: string) => void;
  }

  let {
    value,
    placeholder,
    height,
    onChange,
    class: className,
    oninput,
    ...rest
  }: Props = $props();

  // a model echo must not replace the text being typed
  function show(value: string): Attachment<HTMLTextAreaElement> {
    return (area) => {
      if (document.activeElement !== area && area.value !== value)
        area.value = value;
    };
  }

  function input(event: Event & { currentTarget: HTMLTextAreaElement }) {
    oninput?.(event);
    onChange?.(event.currentTarget.value);
  }
</script>

<!-- @component Multi-line monospaced input, wrapping, with its own scrolling. -->
<textarea
  class={['canon-text-area', className]}
  {placeholder}
  autocomplete="off"
  autocapitalize="off"
  spellcheck="false"
  style={height === undefined ? undefined : `block-size: ${height}px`}
  oninput={input}
  {@attach show(value || '')}
  {...rest}></textarea>
