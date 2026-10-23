<script setup lang="ts">
import '@canon/styles/tokens.css';
import '@canon/components/canon-heading.css';

defineProps<{ text: string }>();
</script>

<template>
	<h3 class="canon-heading">{{ text }}</h3>
</template>
