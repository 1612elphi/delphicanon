<script lang="ts">
  import CanonMenu, {
    type CanonMenuEntry,
    type CanonMenuItem,
  } from '../../src/components/canon-menu.svelte';

  let {
    items,
    onSelect,
  }: { items: CanonMenuEntry[]; onSelect?: (item: CanonMenuItem) => void } =
    $props();
</script>

<CanonMenu {items} {onSelect}>
  {#snippet children(menu)}
    <button type="button" class="opener" {@attach menu.trigger}>Menu</button>
  {/snippet}
</CanonMenu>
