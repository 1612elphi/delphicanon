<script lang="ts">
  import CanonBar from '../../src/components/canon-bar.svelte';
  import CanonRow from '../../src/components/canon-row.svelte';

  let { scene }: { scene: 'labels' | 'stacks' | 'bar' | 'sizing' } = $props();
</script>

{#if scene === 'labels'}
  <CanonRow title="Mode" detail="Caption" form="flush">
    {#snippet children(titleId)}
      <button type="button" aria-labelledby={titleId}>Go</button>
    {/snippet}
  </CanonRow>
{:else if scene === 'stacks'}
  <div style="width: 600px" class="wide">
    <CanonRow title="Label" form="flush">
      <div style="width: 300px; height: 44px"></div>
    </CanonRow>
  </div>
  <div style="width: 300px" class="narrow">
    <CanonRow title="Label" form="flush">
      <div style="width: 300px; height: 44px"></div>
    </CanonRow>
  </div>
{:else if scene === 'bar'}
  <div style="width: 260px">
    <CanonRow title="Detail and icon">
      <CanonBar style="inline-size: 100%; max-inline-size: 160px" share={0.5} />
    </CanonRow>
  </div>
{:else}
  <div style="width: 300px">
    <CanonRow title="A" sizingTitle="A much longer title than this row has">
      <div style="width: 120px; height: 30px"></div>
    </CanonRow>
  </div>
{/if}
