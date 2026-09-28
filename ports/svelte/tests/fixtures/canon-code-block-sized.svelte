<script lang="ts">
  import CanonCodeBlock from '../../src/components/canon-code-block.svelte';

  let { code }: { code: string } = $props();
</script>

<div style="width: 300px">
  <CanonCodeBlock {code} language="css" maxHeight={160} />
</div>
