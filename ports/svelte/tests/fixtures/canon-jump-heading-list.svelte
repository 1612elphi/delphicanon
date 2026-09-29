<script lang="ts">
  import CanonJumpHeading from '../../src/components/canon-jump-heading.svelte';

  let { groups }: { groups: string[] } = $props();
</script>

<div class="list" style="block-size: 200px; overflow-y: auto">
  {#each groups as group (group)}
    <CanonJumpHeading text={group} detail="3" />
    <div style="block-size: 300px"></div>
  {/each}
</div>
