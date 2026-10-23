import CanonPreviewPanel from '#src/components/canon-preview-panel.gts';

export const pane = 'main';
export const order = 5;

<template>
	<CanonPreviewPanel @caption="Preview" @detail="1600 x 900">
		<div class="gallery-swatch"></div>
	</CanonPreviewPanel>
</template>
