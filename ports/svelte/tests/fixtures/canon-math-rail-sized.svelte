<script lang="ts">
  import type { ComponentProps } from 'svelte';
  import CanonMathRail from '../../src/components/canon-math-rail.svelte';

  let props: ComponentProps<typeof CanonMathRail> = $props();
</script>

<div style="width: 400px"><CanonMathRail {...props} /></div>
