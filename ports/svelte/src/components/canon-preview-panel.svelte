<script lang="ts">
  import type { Snippet } from 'svelte';
  import type { HTMLAttributes } from 'svelte/elements';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-preview-panel.css';

  interface Props extends HTMLAttributes<HTMLElement> {
    caption: string;
    /** Trailing note in the caption row, such as the size. */
    detail?: string;
    children?: Snippet;
  }

  let {
    caption,
    detail,
    children,
    class: className,
    ...rest
  }: Props = $props();
</script>

<!-- @component Framed preview: caption row, hairline, then the content flush beneath. -->
<figure class={['canon-preview-panel', className]} {...rest}>
  <figcaption class="canon-preview-panel-header">
    <span class="canon-preview-panel-caption">{caption}</span>
    {#if detail}
      <span class="canon-preview-panel-detail">{detail}</span>
    {/if}
  </figcaption>
  <div class="canon-preview-panel-content">{@render children?.()}</div>
</figure>
