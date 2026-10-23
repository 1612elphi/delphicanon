<script lang="ts" module>
	export const pane = 'main';
	export const order = 25;
</script>

<script lang="ts">
	import CanonDropZone from '../../src/components/canon-drop-zone.svelte';
	import CanonHeading from '../../src/components/canon-heading.svelte';
	import CanonRows from '../../src/components/canon-rows.svelte';
	import CanonStatus from '../../src/components/canon-status.svelte';
	import { icon } from '../icon.ts';
	import file from 'lucide-static/icons/file.svg?raw';

	const dropPrompt = 'Drop an image here';

	let imported = $state('None');

	function showImages(images: ImageBitmap[], names: string[]) {
		const [image] = images;
		if (image)
			imported =
				`${names[0] ?? ''} ${image.width} x ${image.height}`.trim();
	}

	function showFiles(files: File[]) {
		imported = files.map((f) => f.name).join(', ');
	}
</script>

<CanonRows framed>
	<CanonHeading text="Drop zones" />
	<CanonDropZone prompt={dropPrompt} onImages={showImages} />
	<CanonStatus text={imported} tone="muted" row />
	<CanonDropZone
		prompt={dropPrompt}
		icon={icon(file)}
		accept=""
		multiple
		paste={false}
		onFiles={showFiles}
	/>
</CanonRows>
