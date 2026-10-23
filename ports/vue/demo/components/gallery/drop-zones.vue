<script lang="ts">
export const pane = 'main';
export const order = 25;
</script>

<script setup lang="ts">
import { ref } from 'vue';
import CanonDropZone from '../../../src/components/canon-drop-zone.vue';
import CanonHeading from '../../../src/components/canon-heading.vue';
import CanonRows from '../../../src/components/canon-rows.vue';
import CanonStatus from '../../../src/components/canon-status.vue';
import { icon } from '../icon.ts';
import file from 'lucide-static/icons/file.svg?raw';

const dropPrompt = 'Drop an image here';

const imported = ref('None');

function showImages(images: ImageBitmap[], names: string[]) {
	const [image] = images;
	if (image)
		imported.value =
			`${names[0] ?? ''} ${image.width} x ${image.height}`.trim();
}

function showFiles(files: File[]) {
	imported.value = files.map((f) => f.name).join(', ');
}
</script>

<template>
	<CanonRows :framed="true">
		<CanonHeading text="Drop zones" />
		<CanonDropZone :prompt="dropPrompt" :on-images="showImages" />
		<CanonStatus :text="imported" tone="muted" :row="true" />
		<CanonDropZone
			:prompt="dropPrompt"
			:icon="icon(file)"
			accept=""
			:multiple="true"
			:paste="false"
			:on-files="showFiles"
		/>
	</CanonRows>
</template>
