<script lang="ts">
  import type { ComponentProps } from 'svelte';
  import CanonMathKeypad from '../../src/components/canon-math-keypad.svelte';

  let props: ComponentProps<typeof CanonMathKeypad> = $props();
</script>

<div style="width: 420px">
  <CanonMathKeypad {...props} />
</div>
