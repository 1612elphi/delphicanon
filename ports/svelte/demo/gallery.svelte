<script lang="ts">
  import type { Component } from 'svelte';
  import CanonButton from '../src/components/canon-button.svelte';
  import CanonCanvas from '../src/components/canon-canvas.svelte';
  import CanonGrid from '../src/components/canon-grid.svelte';
  import CanonSplit from '../src/components/canon-split.svelte';
  import GalleryArt from './gallery-art.svelte';
  import { icon } from './icon.ts';
  import play from 'lucide-static/icons/play.svg?raw';
  import repeat from 'lucide-static/icons/repeat.svg?raw';
  import square from 'lucide-static/icons/square.svg?raw';

  interface GalleryGroup {
    default: Component;
    pane: 'sidebar' | 'main';
    order: number;
  }

  const groups = Object.entries(
    import.meta.glob<GalleryGroup>('./gallery/*.svelte', { eager: true }),
  )
    .sort(([a, x], [b, y]) => x.order - y.order || a.localeCompare(b))
    .map(([, group]) => group);

  const sidebarGroups = groups
    .filter((g) => g.pane === 'sidebar')
    .map((g) => g.default);
  const mainGroups = groups
    .filter((g) => g.pane === 'main')
    .map((g) => g.default);

  // ?halves: equal panes without a crease, as -galleryHalves on iOS
  const halves = new URLSearchParams(window.location.search).has('halves');
</script>

<!-- @component The port of CanonGalleryViewController: one split, groups from ./gallery/. -->
<CanonSplit class="gallery" {halves}>
  {#snippet banner()}
    <CanonCanvas height={120}><GalleryArt label="All columns" /></CanonCanvas>
  {/snippet}
  {#snippet sidebar()}
    {#each sidebarGroups as Group, i (i)}<Group />{/each}
  {/snippet}
  {#snippet main()}
    {#each mainGroups as Group, i (i)}<Group />{/each}
  {/snippet}
  {#snippet footer()}
    <CanonGrid>
      <CanonButton text="Loop" icon={icon(repeat)} />
      <CanonButton text="Play" icon={icon(play)} kind="primary" />
      <CanonButton text="Stop" icon={icon(square)} />
    </CanonGrid>
  {/snippet}
</CanonSplit>
