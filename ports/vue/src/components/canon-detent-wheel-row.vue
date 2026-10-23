<script setup lang="ts">
import '@canon/styles/tokens.css';
import '@canon/components/canon-detent-wheel-row.css';

defineProps<{
	/** From CanonDetentWheel's slot: 1 on the centre line, 0 a row or more away. */
	focus: number;
}>();
</script>

<!-- A centred label for a CanonDetentWheel row that brightens as it nears the centre line. -->
<template>
	<div
		class="canon-detent-wheel-row"
		:style="{ '--canon-detent-focus': focus }"
	>
		<slot />
	</div>
</template>
