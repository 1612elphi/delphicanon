<script lang="ts">
  import CanonJumpGrid, {
    type CanonJumpSection,
  } from '../../src/components/canon-jump-grid.svelte';
  import type { JumpState } from './jump-state.svelte.ts';

  let {
    state: jump,
    sections,
  }: { state: JumpState; sections: CanonJumpSection[] } = $props();
</script>

<CanonJumpGrid
  open={jump.open}
  {sections}
  current={2}
  onPick={jump.pick}
  onClose={jump.close}
/>
