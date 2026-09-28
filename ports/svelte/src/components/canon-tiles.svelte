<script lang="ts" module>
  export interface CanonTile {
    label: string;
    value: string;
    /** Share of a level bar along the tile's bottom edge, 0 to 1; none draws no bar. */
    level?: number;
  }

  /** Least width of a tile; the grid never goes below two columns. */
  export const tileWidth = 168;
</script>

<script lang="ts">
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLAttributes } from 'svelte/elements';
  import CanonBar from './canon-bar.svelte';
  import CanonGrid from './canon-grid.svelte';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-tiles.css';

  interface Props extends HTMLAttributes<HTMLDivElement> {
    items: CanonTile[];
  }

  let { items, class: className, ...rest }: Props = $props();

  let columns = $state(2);

  const measure: Attachment<HTMLElement> = (element) => {
    let frame = 0;
    // a new column count changes the height; set it next frame, outside this observation
    const observer = new ResizeObserver(([entry]) => {
      const width = entry?.contentRect.width ?? 0;
      const next = Math.max(2, Math.floor(width / tileWidth));
      cancelAnimationFrame(frame);
      if (next !== columns)
        frame = requestAnimationFrame(() => (columns = next));
    });
    observer.observe(element);
    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
    };
  };
</script>

<!--
  @component
  Read-only values as a hairline grid of tiles, label over value. As many
  columns as fit; a short last row stretches its last tile.
-->
<div class={['canon-tiles', className]} {@attach measure} {...rest}>
  <CanonGrid {columns}>
    {#each items as item, i (i)}
      <div class="canon-tiles-tile">
        <span class="canon-tiles-label">{item.label}</span>
        <span class="canon-tiles-value">{item.value}</span>
        {#if item.level !== undefined}
          <CanonBar class="canon-tiles-level" share={item.level} />
        {/if}
      </div>
    {/each}
  </CanonGrid>
</div>
