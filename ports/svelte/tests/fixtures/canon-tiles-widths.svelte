<script lang="ts">
  import CanonTiles, {
    type CanonTile,
  } from '../../src/components/canon-tiles.svelte';

  let { items }: { items: CanonTile[] } = $props();
</script>

<div class="wide" style="width: 600px"><CanonTiles {items} /></div>
<div class="narrow" style="width: 200px"><CanonTiles {items} /></div>
