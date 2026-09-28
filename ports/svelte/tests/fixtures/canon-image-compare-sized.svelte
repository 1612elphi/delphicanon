<script lang="ts">
  import CanonImageCompare from '../../src/components/canon-image-compare.svelte';

  let { picture }: { picture: string } = $props();
</script>

<div style="width: 400px; height: 200px">
  <CanonImageCompare before={picture} after={picture} afterTitle="Grey" />
</div>
