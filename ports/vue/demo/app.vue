<script setup lang="ts">
import CanonToast from '../src/components/canon-toast.vue';
import ColourPage from './components/colour-page.vue';
import Gallery from './components/gallery.vue';

// ?page=colour: the colour page, as CanonColourGalleryViewController
const colour =
	new URLSearchParams(window.location.search).get('page') === 'colour';
document.title = 'Canon';
</script>

<template>
	<ColourPage v-if="colour" />
	<Gallery v-else />
	<CanonToast />
</template>
