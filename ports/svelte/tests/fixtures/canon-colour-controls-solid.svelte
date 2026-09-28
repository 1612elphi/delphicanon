<script lang="ts">
  import CanonColourControls, {
    type CanonColourSolidState,
  } from '../../src/components/canon-colour-controls.svelte';
  import CanonColourSolid from '../../src/components/canon-colour-solid.svelte';
  import CanonRows from '../../src/components/canon-rows.svelte';

  let { model, solid }: { model: CanonColourSolidState; solid?: boolean } =
    $props();
</script>

{#if solid}
  <div style="width: 400px">
    <div style="height: 200px">
      <CanonColourSolid
        space={model.space}
        point={model.point}
        animated={model.animated}
        sliceAxis={model.sliceAxis}
        isOrtho={model.isOrtho}
        showsWhole={model.showsWhole}
        onChange={model.pick}
      />
    </div>
    <CanonRows><CanonColourControls state={model} /></CanonRows>
  </div>
{:else}
  <CanonRows><CanonColourControls state={model} /></CanonRows>
{/if}
