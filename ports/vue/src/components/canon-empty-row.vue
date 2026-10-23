<script setup lang="ts">
import '@canon/styles/tokens.css';
import '@canon/components/canon-empty-row.css';

defineProps<{ text: string }>();
</script>

<template>
	<div class="canon-empty-row">{{ text }}</div>
</template>
