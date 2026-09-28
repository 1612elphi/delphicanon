<script lang="ts">
  import CanonStepper from '../../src/components/canon-stepper.svelte';

  let { onStep }: { onStep: (direction: -1 | 1) => void } = $props();
</script>

<CanonStepper {onStep}><input aria-label="n" /></CanonStepper>
