<script lang="ts">
  import CanonReadoutBand from '../../src/components/canon-readout-band.svelte';

  const playing = { playhead: 83.4, playing: true, looping: true };
  const idle = {};
</script>

<div class="over" style="width: 400px; height: 120px">
  <CanonReadoutBand transport={playing}>
    {#snippet children(playhead)}
      <span class="strip">{playhead}</span>
    {/snippet}
  </CanonReadoutBand>
</div>
<div class="below" style="width: 400px; height: 100px">
  <CanonReadoutBand transport={idle} readout="below">
    <span class="strip"></span>
  </CanonReadoutBand>
</div>
