<script lang="ts">
  import CanonMathView from '../../src/components/canon-math-view.svelte';

  let { text }: { text: string } = $props();
</script>

<div style="width: 300px; height: 80px">
  <CanonMathView {text} morphs style="height: 80px" />
</div>
