<script lang="ts">
  import CanonSheet from '../../src/components/canon-sheet.svelte';
  import type { DialogState } from './dialog-state.svelte.ts';

  let { state: sheet }: { state: DialogState } = $props();
</script>

<CanonSheet
  open={sheet.open}
  edge={sheet.edge}
  title="Sheet"
  onClose={sheet.close}
>
  <p>Body</p>
</CanonSheet>
