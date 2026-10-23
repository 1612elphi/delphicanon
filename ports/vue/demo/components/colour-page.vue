<script setup lang="ts">
import { computed, ref } from 'vue';
import CanonButton from '../../src/components/canon-button.vue';
import CanonCanvas from '../../src/components/canon-canvas.vue';
import CanonColourCard from '../../src/components/canon-colour-card.vue';
import CanonColourControls, {
	CanonColourSolidState,
} from '../../src/components/canon-colour-controls.vue';
import CanonColourSolid from '../../src/components/canon-colour-solid.vue';
import CanonColourNotationInput from '../../src/components/canon-colour-notation-input.vue';
import CanonColourStrip from '../../src/components/canon-colour-strip.vue';
import CanonDetentWheel from '../../src/components/canon-detent-wheel.vue';
import CanonDetentWheelRow from '../../src/components/canon-detent-wheel-row.vue';
import CanonHeading from '../../src/components/canon-heading.vue';
import CanonLoupe from '../../src/components/canon-loupe.vue';
import CanonPaletteCard from '../../src/components/canon-palette-card.vue';
import CanonRow from '../../src/components/canon-row.vue';
import CanonRows from '../../src/components/canon-rows.vue';
import CanonSegmented from '../../src/components/canon-segmented.vue';
import CanonSplit from '../../src/components/canon-split.vue';
import CanonSwitch from '../../src/components/canon-switch.vue';
import CanonValueLine from '../../src/components/canon-value-line.vue';
import { elementDirective } from '../../src/lib/directive.ts';
import {
	fromOklch,
	hex,
	luminance as luminanceOf,
	oklabToLinear,
	oklch,
	parseHex,
	type Rgb,
} from '@canon/lib/colour.ts';
import { solidSpaces, spaceNames } from '@canon/lib/colour-space.ts';
import { frame } from '@canon/lib/loupe.ts';
import { icon } from './icon.ts';
import copy from 'lucide-static/icons/copy.svg?raw';
import save from 'lucide-static/icons/download.svg?raw';
import share from 'lucide-static/icons/share.svg?raw';

// stand-in for the app's 4,926 colour names
const names: [string, Rgb][] = (
	[
		['Black', '000000'],
		['White', 'FFFFFF'],
		['Grey', '808080'],
		['Red', 'E53935'],
		['Orange', 'FB8C00'],
		['Yellow', 'FDD835'],
		['Olive', '808000'],
		['Green', '43A047'],
		['Forest', '1E6626'],
		['Teal', '00897B'],
		['Cyan', '00ACC1'],
		['Blue', '1E88E5'],
		['Navy', '1A237E'],
		['Purple', '8E24AA'],
		['Pink', 'D81B60'],
		['Brown', '6D4C41'],
		['Cream', 'FAF5E6'],
	] as const
).map(([name, code]) => [name, parseHex(code)!]);

function nameOf(code: string): string {
	const [r, g, b] = parseHex(code)!;
	let best = names[0]!;
	let distance = Infinity;
	for (const entry of names) {
		const [x, y, z] = entry[1];
		const d = (r - x) ** 2 + (g - y) ** 2 + (b - z) ** 2;
		if (d < distance) [best, distance] = [entry, d];
	}
	return best[0];
}

const closestName = (colour: Rgb) => nameOf(hex(colour));

function maxChroma(l: number, h: number): number {
	const radians = (h * Math.PI) / 180;
	let [low, high] = [0, 0.5];
	for (let i = 0; i < 24; i++) {
		const mid = (low + high) / 2;
		const inside = oklabToLinear(
			l,
			mid * Math.cos(radians),
			mid * Math.sin(radians),
		).every((v) => v >= -1e-5 && v <= 1 + 1e-5);
		if (inside) low = mid;
		else high = mid;
	}
	return low;
}

function inGamut(l: number, c: number, h: number): Rgb {
	const hue = ((h % 360) + 360) % 360;
	return fromOklch(l, Math.min(c, maxChroma(l, hue)), hue);
}

const views = ['Slice', 'Ortho', 'Cut'];
const harmonyKinds = ['Analogous', 'Split'];
const normal = [
	[1, 0, 0],
	[0, 1, 0],
	[0, 0, 1],
];
const deuteranopia = [
	[0.625, 0.375, 0],
	[0.7, 0.3, 0],
	[0, 0.3, 0.7],
];

const spaceName = (index: number) => spaceNames[solidSpaces[index]!];
const tintDigits = (character: string) =>
	/\d/.test(character)
		? 'var(--canon-primary)'
		: 'var(--canon-foreground)';

// the colour's shades around the middle pixel, as the iOS gallery draws them
function shadedPixels(colour: Rgb): ImageData {
	const side = 15;
	const pixels = new ImageData(side, side);
	for (let y = 0; y < side; y++) {
		for (let x = 0; x < side; x++) {
			const toward = (x + y) % 2 === 0 ? 1 : 0;
			const by = (Math.abs(x - 7) + Math.abs(y - 7)) / 16;
			const at = (y * side + x) * 4;
			colour.forEach((channel, i) => {
				pixels.data[at + i] = Math.round(
					(channel + (toward - channel) * by) *
						255,
				);
			});
			pixels.data[at + 3] = 255;
		}
	}
	return pixels;
}

const vPlaceLoupe = elementDirective<void>((loupe) => {
	const box = loupe.parentElement!;
	const observer = new ResizeObserver(() => {
		const { clientWidth: width, clientHeight: height } = box;
		const spot = frame(
			{ x: width / 2, y: height / 2 + 60 },
			112,
			24,
			{ width, height },
			8,
		);
		loupe.style.insetInlineStart = `${spot.x}px`;
		loupe.style.insetBlockStart = `${spot.y}px`;
	});
	observer.observe(box);
	return () => observer.disconnect();
});

// ?colourSpace=<picker index>&colourRow=<0-3>&colourView=<0-2>&colourCrease: the starting state, as the iOS launch arguments
const query = new URLSearchParams(window.location.search);
const number = (key: string) => Number(query.get(key) ?? 0) || 0;
const startView = number('colourView');
const crease = query.has('colourCrease');

const state = Object.assign(
	new CanonColourSolidState({
		space: query.has('colourSpace')
			? solidSpaces[number('colourSpace')]
			: 'hsl',
		activeRow: number('colourRow'),
	}),
	{ slices: startView !== 2, viewPlane: startView === 1 },
);
const view = ref(startView);
const split = ref(false);
const stripPalette = ref(false);
const deuteranopiaOn = ref(false);

const colour = computed(() => state.colour);

const harmony = computed<Rgb[]>(() => {
	const [l, c, h] = oklch(colour.value);
	return (split.value ? [0, 150, 210] : [0, 30, -30]).map((turn) =>
		inGamut(l, c, h + turn),
	);
});
const marks = computed(() => harmony.value.slice(1));
const shades = computed<Rgb[]>(() => {
	const [, c, h] = oklch(colour.value);
	return Array.from({ length: 9 }, (_, i) =>
		inGamut(0.95 - i * 0.085, c, h),
	);
});
const decimal = computed(
	() => `rgb(${colour.value.map((v) => v.toFixed(4)).join(', ')})`,
);
const luminance = computed(() => luminanceOf(colour.value).toFixed(3));
const spaceIndex = computed(() => solidSpaces.indexOf(state.space));
const loupePixels = computed(() => shadedPixels(colour.value));
const repeatedHex = computed(() => hex(colour.value).repeat(4));
const longHex = computed(() => hex(colour.value).repeat(5));
const palette = computed(() =>
	stripPalette.value ? harmony.value : undefined,
);
const vision = computed(() => (deuteranopiaOn.value ? deuteranopia : normal));

function showView(index: number) {
	view.value = index;
	state.slices = index !== 2;
	state.viewPlane = index === 1;
}

const pickSpace = (index: number) => state.selectSpace(solidSpaces[index]!);
const pickHarmony = (index: number) => (split.value = index === 1);
const showStripPalette = (on: boolean) => (stripPalette.value = on);
const showDeuteranopia = (on: boolean) => (deuteranopiaOn.value = on);

const copyPalette = () =>
	void navigator.clipboard?.writeText(harmony.value.map(hex).join('\n'));
</script>

<!-- The port of CanonColourGalleryViewController: the solid, colour cards and palette cards, driven by one colour. -->
<template>
	<CanonSplit
		class="gallery"
		:halves="true"
		:collapses-to="240"
		:picture-meets-crease="crease"
	>
		<template #sidebar>
			<CanonCanvas
				:aspect="1"
				:max-height="640"
				background="var(--canon-muted)"
			>
				<div class="gallery-solid">
					<CanonColourSolid
						class="gallery-solid-picture"
						:space="state.space"
						:point="state.point"
						:animated="state.animated"
						:slice-axis="state.sliceAxis"
						:is-ortho="state.isOrtho"
						:shows-whole="state.showsWhole"
						:marks="marks"
						:vision="vision"
						:on-change="state.pick"
						:closest-name="closestName"
					/>
					<CanonColourStrip
						:colour="colour"
						:palette="palette"
						:name-of="nameOf"
					/>
				</div>
			</CanonCanvas>
		</template>
		<template #main>
			<CanonRows :framed="true">
				<CanonHeading text="Solid" />
				<CanonColourControls :state="state">
					<CanonRow title="View" form="flush">
						<CanonSegmented
							:items="views"
							:selected="view"
							:on-change="showView"
						/>
					</CanonRow>
				</CanonColourControls>
				<CanonRow
					v-slot="{ titleId }"
					title="Strip palette"
				>
					<CanonSwitch
						:on="stripPalette"
						:on-change="showStripPalette"
						:aria-labelledby="titleId"
					/>
				</CanonRow>
				<CanonRow
					v-slot="{ titleId }"
					title="Deuteranopia"
				>
					<CanonSwitch
						:on="deuteranopiaOn"
						:on-change="showDeuteranopia"
						:aria-labelledby="titleId"
					/>
				</CanonRow>
			</CanonRows>
			<CanonColourCard :colour="colour" :name-of="nameOf" />
			<CanonColourCard
				:colour="colour"
				layout="row"
				:name-of="nameOf"
			/>
			<CanonRows :framed="true">
				<CanonHeading text="Value lines" />
				<CanonValueLine
					label="Decimal RGB"
					:value="decimal"
					:label-width="92"
				/>
				<CanonValueLine
					label="Luminance"
					:value="luminance"
					:label-width="92"
				/>
				<CanonValueLine
					label="Above"
					:value="hex(colour)"
					layout="above"
				/>
				<CanonValueLine
					label="x ="
					:value="repeatedHex"
					layout="wrapping"
				/>
				<CanonValueLine
					label="Nil"
					:value="null"
					layout="wrapping"
				/>
				<CanonValueLine
					label="01"
					:value="hex(colour)"
					layout="numbered"
					:lit="true"
				/>
				<CanonValueLine
					label="02"
					:value="longHex"
					layout="numbered"
					:wraps="true"
					:tint="tintDigits"
				/>
			</CanonRows>
			<CanonRows :framed="true">
				<CanonHeading text="Notation input" />
				<CanonRow
					v-slot="{ titleId }"
					title="Any notation"
					form="stacked"
				>
					<CanonColourNotationInput
						:colour="colour"
						:on-colour="state.use"
						:labelled-by="titleId"
					/>
				</CanonRow>
				<CanonHeading text="Loupe" />
				<CanonCanvas
					:height="200"
					background="var(--canon-muted)"
				>
					<CanonLoupe
						v-place-loupe
						class="gallery-loupe"
						:pixels="loupePixels"
						:colour="colour"
					/>
				</CanonCanvas>
				<CanonHeading text="Detent wheel" />
				<CanonCanvas :height="200">
					<CanonDetentWheel
						v-slot="{ index, focus }"
						:count="solidSpaces.length"
						:selected="spaceIndex"
						:on-select="pickSpace"
						:text="spaceName"
						label="Space"
					>
						<CanonDetentWheelRow
							:focus="focus"
							>{{
								spaceName(index)
							}}</CanonDetentWheelRow
						>
					</CanonDetentWheel>
				</CanonCanvas>
			</CanonRows>
			<CanonPaletteCard
				title="Harmony"
				:colours="harmony"
				:name-of="nameOf"
			>
				<template #picker>
					<CanonSegmented
						:items="harmonyKinds"
						:selected="split ? 1 : 0"
						:on-change="pickHarmony"
					/>
				</template>
				<template #actions>
					<CanonButton
						text="Copy"
						:icon="icon(copy)"
						kind="cell"
						:flashes-copied="true"
						:on-click="copyPalette"
					/>
					<CanonButton
						text="Export"
						:icon="icon(share)"
						kind="cell"
					/>
					<CanonButton
						text="Save"
						:icon="icon(save)"
						kind="cell"
					/>
				</template>
			</CanonPaletteCard>
			<CanonPaletteCard
				title="Shades"
				:colours="shades"
				:height="120"
				:name-of="nameOf"
			/>
		</template>
	</CanonSplit>
</template>
