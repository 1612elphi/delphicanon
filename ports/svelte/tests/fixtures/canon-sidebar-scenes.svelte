<script lang="ts">
  import CanonHeading from '../../src/components/canon-heading.svelte';
  import CanonSidebar from '../../src/components/canon-sidebar.svelte';
  import CanonSidebarRow from '../../src/components/canon-sidebar-row.svelte';

  let { scene }: { scene: 'parts' | 'rail' } = $props();
</script>

{#if scene === 'parts'}
  <div style="height: 400px">
    <CanonSidebar aria-label="Main">
      {#snippet hero()}<img alt="" />{/snippet}
      <CanonHeading text="Modules" />
      <CanonSidebarRow title="Toolbox" />
      <CanonSidebarRow title="General" />
    </CanonSidebar>
  </div>
{:else}
  <div style="display: flex; height: 400px">
    <CanonSidebar class="wide">
      <CanonHeading text="Modules" />
      <CanonSidebarRow title="Toolbox" />
    </CanonSidebar>
    <CanonSidebar class="rail" collapsed>
      <CanonHeading text="Modules" />
      <CanonSidebarRow title="Toolbox" />
    </CanonSidebar>
  </div>
{/if}
