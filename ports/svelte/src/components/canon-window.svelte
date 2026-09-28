<script lang="ts">
  import type { Snippet } from 'svelte';
  import type { HTMLAttributes } from 'svelte/elements';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-window.css';

  interface Props extends Omit<
    HTMLAttributes<HTMLElement>,
    'title' | 'children'
  > {
    title?: string;
    /** Any of the three shows all three controls; one without a callback is disabled. */
    onClose?: () => void;
    onMinimise?: () => void;
    onZoom?: () => void;
    /** Draws the 2 px tool frame around the window. */
    framed?: boolean;
    /** Trailing controls in the title bar. */
    toolbar?: Snippet;
    /** A strip under the title bar. */
    menubar?: Snippet;
    /** A CanonSidebar; it collapses to its rail when the body is narrower than 640 px. */
    sidebar?: Snippet;
    /** The detail: a CanonPage or CanonSplit fills it. */
    main?: Snippet;
  }

  let {
    title,
    onClose,
    onMinimise,
    onZoom,
    framed,
    toolbar,
    menubar,
    sidebar,
    main,
    class: className,
    ...rest
  }: Props = $props();

  const uid = $props.id();
  const titleId = `${uid}-title`;
  const controls = $derived(
    onClose !== undefined || onMinimise !== undefined || onZoom !== undefined,
  );
</script>

<!--
  @component
  Desktop-style window chrome (MainWindow): a title bar, an optional menu
  bar, then the sidebar beside the detail. Fills its container.
-->
<section
  class={['canon-window', framed && 'canon-window--framed', className]}
  aria-labelledby={title ? titleId : undefined}
  {...rest}
>
  <header class="canon-window-bar">
    {#if controls}
      <div class="canon-window-controls">
        <button
          type="button"
          class="canon-window-control canon-window-control--close"
          aria-label="Close"
          disabled={!onClose}
          onclick={() => onClose?.()}
        ></button>
        <button
          type="button"
          class="canon-window-control canon-window-control--minimise"
          aria-label="Minimise"
          disabled={!onMinimise}
          onclick={() => onMinimise?.()}
        ></button>
        <button
          type="button"
          class="canon-window-control canon-window-control--zoom"
          aria-label="Zoom"
          disabled={!onZoom}
          onclick={() => onZoom?.()}
        ></button>
      </div>
    {/if}
    <div class="canon-window-title" id={titleId}>{title}</div>
    {#if toolbar}
      <div class="canon-window-toolbar">{@render toolbar()}</div>
    {/if}
  </header>
  {#if menubar}
    <div class="canon-window-menubar">{@render menubar()}</div>
  {/if}
  <div class="canon-window-body">
    {@render sidebar?.()}
    <div class="canon-window-main">{@render main?.()}</div>
  </div>
</section>
