<script lang="ts">
export const pane = 'main';
export const order = 10;
</script>

<script setup lang="ts">
import { computed, ref } from 'vue';
import CanonCanvas from '../../../src/components/canon-canvas.vue';
import GalleryArt from '../gallery-art.vue';

const lines = ref(1);
const text = computed(() =>
	Array.from({ length: lines.value }, (_, i) => `Line ${i + 1}`),
);
const more = () => (lines.value = (lines.value % 4) + 1);
</script>

<template>
	<CanonCanvas :aspect="4"
		><GalleryArt label="Column canvas"
	/></CanonCanvas>
	<CanonCanvas :fitting="true" :animated="true">
		<button type="button" class="gallery-fit" @click="more">
			<span v-for="line in text" :key="line">{{ line }}</span>
		</button>
	</CanonCanvas>
	<CanonCanvas :aspect="4" boxing="unlessWide">
		<GalleryArt label="Boxed unless wide" />
	</CanonCanvas>
</template>
