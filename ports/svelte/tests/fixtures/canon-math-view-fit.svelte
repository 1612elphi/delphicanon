<script lang="ts">
  import CanonMathView from '../../src/components/canon-math-view.svelte';
</script>

<div style="width: 40px">
  <CanonMathView text="x^2 + 1/2" />
</div>
<CanonMathView class="faint" text="y" faint />
<CanonMathView class="shown" text="b*c^(-1)" presents />
