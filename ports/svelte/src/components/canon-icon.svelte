<script lang="ts">
	import { unsized } from '../lib/control-icons.ts';

	interface Props {
		/** A lucide SVG string (`lucide-static/icons/<name>.svg?raw`). */
		svg: string;
	}

	let { svg }: Props = $props();
</script>

<!-- eslint-disable-next-line svelte/no-at-html-tags -->
{@html unsized(svg)}
