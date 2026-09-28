<script lang="ts">
  import type { Snippet } from 'svelte';
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLAttributes } from 'svelte/elements';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-canvas.css';

  interface Props extends HTMLAttributes<HTMLDivElement> {
    /** Fixed height of the band in px, rules included. */
    height?: number;
    /** Width over height of the content; used when `height` is not set. */
    aspect?: number;
    /** Caps the band's height in a wide column; the content letterboxes itself. */
    maxHeight?: number;
    /** never: always an edge-to-edge band. unlessWide: a band beside a sidebar, a framed box everywhere else. */
    boxing?: 'never' | 'unlessWide';
    /** CSS colour behind the content; default the card colour. */
    background?: string;
    /** Tiles `--canon-pattern` faintly under the content. A CanonSplit banner always has it. */
    pattern?: boolean;
    /**
     * Takes the band's height from the content's own height at the column's
     * width, plus the rules; content with no height hides the band.
     */
    fitting?: boolean;
    /** With `fitting`: a change of the content's height at the same width animates the band. */
    animated?: boolean;
    children?: Snippet;
  }

  let {
    height,
    aspect,
    maxHeight,
    boxing,
    background,
    pattern,
    fitting,
    animated,
    children,
    class: className,
    ...rest
  }: Props = $props();

  let fitted = $state<number>();
  let eases = $state(false);

  const collapsed = $derived(fitting && fitted === 0);
  const style = $derived.by(() => {
    const natural =
      height !== undefined
        ? `${height}px`
        : `calc(100cqw / ${aspect ?? 1} + 2 * var(--canon-frame))`;
    const parts = [`--canon-canvas-natural: ${natural}`];
    if (fitting && fitted !== undefined)
      parts.push(`--canon-canvas-fitted: ${fitted}px`);
    if (maxHeight !== undefined)
      parts.push(`--canon-canvas-max: ${maxHeight}px`);
    if (background) parts.push(`--canon-canvas-background: ${background}`);
    return parts.join('; ');
  });

  const fit: Attachment<HTMLElement> = (element) => {
    let width: number | undefined;
    const observer = new ResizeObserver(([entry]) => {
      const box = entry?.borderBoxSize[0];
      if (!box) return;
      eases = Boolean(animated) && box.inlineSize === width;
      width = box.inlineSize;
      fitted = box.blockSize;
    });
    observer.observe(element);
    return () => observer.disconnect();
  };
</script>

<!--
  @component
  Edge-to-edge band for a picture, a preview or a drawing surface, ruled
  above and below. As a page section it spans its column; as a CanonSplit
  banner it spans every column. Place it between blocks of CanonRows.
-->
<div
  class={[
    'canon-canvas',
    boxing === 'unlessWide' && 'canon-canvas--unless-wide',
    pattern && 'canon-canvas--pattern',
    fitting && 'canon-canvas--fitting',
    collapsed && 'canon-canvas--collapsed',
    eases && 'canon-canvas--eases',
    className,
  ]}
  {style}
  data-canon-height={height}
  data-canon-aspect={aspect}
  {...rest}
>
  <div class="canon-canvas-content">
    {#if fitting}
      <div class="canon-canvas-fit" {@attach fit}>{@render children?.()}</div>
    {:else}
      {@render children?.()}
    {/if}
  </div>
</div>
