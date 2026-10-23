<script setup lang="ts">
import '@canon/styles/tokens.css';
import '@canon/components/canon-rows.css';

defineProps<{
	/** Draws the 2 px tool frame around the rows. */
	framed?: boolean;
}>();
</script>

<!-- Rows separated by hairlines: the gaps show the border colour. -->
<template>
	<div class="canon-rows" :class="{ 'canon-rows--framed': framed }">
		<slot />
	</div>
</template>
