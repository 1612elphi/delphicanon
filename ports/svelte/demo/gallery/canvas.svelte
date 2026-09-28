<script lang="ts" module>
  export const pane = 'main';
  export const order = 10;
</script>

<script lang="ts">
  import CanonCanvas from '../../src/components/canon-canvas.svelte';
  import GalleryArt from '../gallery-art.svelte';

  let lines = $state(1);
  const text = $derived(
    Array.from({ length: lines }, (_, i) => `Line ${i + 1}`),
  );
  const more = () => (lines = (lines % 4) + 1);
</script>

<CanonCanvas aspect={4}><GalleryArt label="Column canvas" /></CanonCanvas>
<CanonCanvas fitting animated>
  <button type="button" class="gallery-fit" onclick={more}>
    {#each text as line (line)}<span>{line}</span>{/each}
  </button>
</CanonCanvas>
<CanonCanvas aspect={4} boxing="unlessWide">
  <GalleryArt label="Boxed unless wide" />
</CanonCanvas>
