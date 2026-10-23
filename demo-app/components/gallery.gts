import type { ComponentLike } from '@glint/template';
import CanonButton from '#src/components/canon-button.gts';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonGrid from '#src/components/canon-grid.gts';
import CanonSplit from '#src/components/canon-split.gts';
import GalleryArt from './gallery-art.gts';
import Icon from './icon.gts';
import play from 'lucide-static/icons/play.svg?raw';
import repeat from 'lucide-static/icons/repeat.svg?raw';
import square from 'lucide-static/icons/square.svg?raw';

interface GalleryGroup {
	default: ComponentLike;
	pane: 'sidebar' | 'main';
	order: number;
}

const groups = Object.entries(
	import.meta.glob<GalleryGroup>('./gallery/*.gts', { eager: true }),
)
	.sort(([a, x], [b, y]) => x.order - y.order || a.localeCompare(b))
	.map(([, group]) => group);

const sidebar = groups
	.filter((g) => g.pane === 'sidebar')
	.map((g) => g.default);
const main = groups.filter((g) => g.pane === 'main').map((g) => g.default);

// ?halves: equal panes without a crease, as -galleryHalves on iOS
const halves = new URLSearchParams(window.location.search).has('halves');

/** The port of CanonGalleryViewController: one split, groups from ./gallery/. */
<template>
	<CanonSplit class="gallery" @halves={{halves}}>
		<:banner>
			<CanonCanvas @height={{120}}><GalleryArt
					@label="All columns"
				/></CanonCanvas>
		</:banner>
		<:sidebar>
			{{#each sidebar as |Group|}}<Group />{{/each}}
		</:sidebar>
		<:main>
			{{#each main as |Group|}}<Group />{{/each}}
		</:main>
		<:footer>
			<CanonGrid>
				<CanonButton
					@text="Loop"
					@icon={{component Icon svg=repeat}}
				/>
				<CanonButton
					@text="Play"
					@icon={{component Icon svg=play}}
					@kind="primary"
				/>
				<CanonButton
					@text="Stop"
					@icon={{component Icon svg=square}}
				/>
			</CanonGrid>
		</:footer>
	</CanonSplit>
</template>
