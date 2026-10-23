<script lang="ts">
	import CanonToast from '../src/components/canon-toast.svelte';
	import ColourPage from './colour-page.svelte';
	import Gallery from './gallery.svelte';

	// ?page=colour: the colour page, as CanonColourGalleryViewController
	const colour =
		new URLSearchParams(window.location.search).get('page') ===
		'colour';
</script>

{#if colour}<ColourPage />{:else}<Gallery />{/if}
<CanonToast />
