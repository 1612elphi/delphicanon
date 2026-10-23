<script lang="ts">
export const pane = 'main';
export const order = 5;
</script>

<script setup lang="ts">
import CanonPreviewPanel from '../../../src/components/canon-preview-panel.vue';
import '../../../../../demo-app/components/gallery/display.css';
</script>

<template>
	<CanonPreviewPanel caption="Preview" detail="1600 x 900">
		<div class="gallery-swatch"></div>
	</CanonPreviewPanel>
</template>
