<script lang="ts" module>
  import type { CanonDialogProps } from './canon-dialog.svelte';

  export interface CanonJumpSection {
    title: string;
    /** Under the title, as a count of the group's items. */
    detail?: string;
  }

  export interface CanonJumpGridProps extends Omit<
    CanonDialogProps,
    | 'title'
    | 'message'
    | 'alert'
    | 'dismissable'
    | 'header'
    | 'children'
    | 'footer'
    | 'keyframes'
    | 'onClose'
  > {
    open: boolean;
    sections: CanonJumpSection[];
    /** The lit tile: the group in view. It takes focus when the grid opens. */
    current?: number;
    /** The dialog's accessible name; default Sections. */
    label?: string;
    /** A tile was picked; called after the grid has closed and focus has returned. */
    onPick?: (index: number) => void;
    /** Every close. The owner sets `open` false here. */
    onClose?: () => void;
  }

  // iOS crossDissolve: no scale
  const fade = (): Keyframe[] => [{ opacity: 0 }, { opacity: 1 }];
</script>

<script lang="ts">
  import type { Attachment } from 'svelte/attachments';
  import CanonDialog, { type CanonDialogClose } from './canon-dialog.svelte';
  import CanonGrid from './canon-grid.svelte';
  import { press } from '../lib/press.ts';
  import { appearDelay, jumpColumns } from '@canon/lib/jump.ts';
  import { reducedMotion, springEasing } from '@canon/lib/motion.ts';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-jump-grid.css';

  let {
    open,
    sections,
    current,
    label,
    onPick,
    onClose,
    class: className,
    ...rest
  }: CanonJumpGridProps = $props();

  const tileSpring = springEasing(0.7);

  let columns = $state(
    typeof window === 'undefined' ? 2 : jumpColumns(window.innerWidth),
  );

  const tiles = $derived(
    sections.map((section, index) => ({
      ...section,
      index,
      value: String(index),
      lit: index === current,
    })),
  );

  function appear(
    index: number,
    count: number,
    from: number,
  ): Attachment<HTMLElement> {
    return (tile) => {
      if (reducedMotion()) return;
      tile.animate(
        [
          { opacity: 0, transform: 'scale(0.8) rotate(-0.05rad)' },
          { opacity: 1, transform: 'none' },
        ],
        {
          duration: 450,
          delay: appearDelay(index, count, from),
          easing: tileSpring,
          fill: 'backwards',
        },
      );
    };
  }

  const measure: Attachment<HTMLElement> = (holder) => {
    const observer = new ResizeObserver(([entry]) => {
      columns = jumpColumns(entry?.contentRect.width ?? 0);
    });
    observer.observe(holder.closest('dialog') ?? holder);
    return () => observer.disconnect();
  };

  function outside(close: CanonDialogClose, event: MouseEvent) {
    if (!(event.target as Element).closest('.canon-jump-grid-tile')) close();
  }

  function closed(value: string) {
    onClose?.();
    if (value !== '') onPick?.(Number(value));
  }
</script>

<!--
  @component
  The Windows Phone jump list: every group of a long list as a tile over
  the page, the group in view lit. A pick closes it and reports the group;
  a click beside the tiles or Escape closes it.
-->
<CanonDialog
  class={['canon-jump-grid', className]}
  aria-label={label || 'Sections'}
  {open}
  keyframes={fade}
  onClose={closed}
  {...rest}
>
  {#snippet children(close)}
    <!-- svelte-ignore a11y_click_events_have_key_events, a11y_no_static_element_interactions -->
    <div
      class="canon-jump-grid-holder"
      {@attach measure}
      onclick={(event) => outside(close, event)}
    >
      <CanonGrid {columns} boxed>
        {#each tiles as tile (tile.index)}
          <!-- svelte-ignore a11y_autofocus -->
          <button
            type="button"
            class={[
              'canon-jump-grid-tile',
              tile.lit && 'canon-jump-grid-tile--lit',
            ]}
            aria-current={tile.lit ? 'true' : undefined}
            autofocus={tile.lit}
            {@attach press}
            {@attach appear(tile.index, tiles.length, current ?? 0)}
            onclick={() => close(tile.value)}
          >
            <span class="canon-jump-grid-title">{tile.title}</span>
            {#if tile.detail}
              <span class="canon-jump-grid-detail">{tile.detail}</span>
            {/if}
          </button>
        {/each}
      </CanonGrid>
    </div>
  {/snippet}
</CanonDialog>
