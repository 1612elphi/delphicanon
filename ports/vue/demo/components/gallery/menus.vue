<script lang="ts">
export const pane = 'main';
export const order = 21;
</script>

<script setup lang="ts">
import { computed, ref } from 'vue';
import CanonButton from '../../../src/components/canon-button.vue';
import CanonCanvas from '../../../src/components/canon-canvas.vue';
import CanonContextMenu from '../../../src/components/canon-context-menu.vue';
import CanonGrid from '../../../src/components/canon-grid.vue';
import CanonHeading from '../../../src/components/canon-heading.vue';
import CanonMenu, {
	type CanonMenuEntry,
	type CanonMenuItem,
} from '../../../src/components/canon-menu.vue';
import CanonMenuBar, {
	type CanonMenuBarMenu,
} from '../../../src/components/canon-menu-bar.vue';
import CanonPopover from '../../../src/components/canon-popover.vue';
import CanonRow from '../../../src/components/canon-row.vue';
import CanonRows from '../../../src/components/canon-rows.vue';
import CanonSegmented from '../../../src/components/canon-segmented.vue';
import CanonSlider from '../../../src/components/canon-slider.vue';
import CanonTooltip from '../../../src/components/canon-tooltip.vue';
import type { CanonPlacement } from '@canon/lib/popover.ts';
import GalleryArt from '../gallery-art.vue';
import { icon } from '../icon.ts';
import chevronDown from 'lucide-static/icons/chevron-down.svg?raw';
import copy from 'lucide-static/icons/copy.svg?raw';
import pencil from 'lucide-static/icons/pencil.svg?raw';
import share from 'lucide-static/icons/share.svg?raw';
import trash from 'lucide-static/icons/trash-2.svg?raw';
import '../../../../../demo-app/components/gallery/menus.css';

const rule = { kind: 'separator' } as const;
const sides = ['Top', 'Right', 'Bottom', 'Left'];
const edges = ['Start', 'Centre', 'End'];
const sizes = ['Small', 'Medium', 'Large'];

const chosen = ref('—');
const grid = ref(true);
const snap = ref(false);
const rulers = ref(false);
const size = ref('Medium');
const side = ref(2);
const edge = ref(0);
const opacity = ref(0.8);

const placement = computed(() => {
	const s = ['top', 'right', 'bottom', 'left'][side.value]!;
	const e = ['-start', '', '-end'][edge.value]!;
	return `${s}${e}` as CanonPlacement;
});

const items = computed((): CanonMenuEntry[] => [
	{ title: 'Duplicate', icon: icon(copy), shortcut: '⌘D' },
	{ title: 'Rename…', icon: icon(pencil) },
	{
		title: 'Share',
		icon: icon(share),
		items: [
			{ title: 'Copy link' },
			{ title: 'Email' },
			{ title: 'Messages' },
		],
	},
	rule,
	{
		title: 'Grid',
		kind: 'checkbox',
		checked: grid.value,
		shortcut: "⌘'",
	},
	{ title: 'Snap', kind: 'checkbox', checked: snap.value },
	rule,
	...sizes.map((title) => ({
		title,
		kind: 'radio' as const,
		checked: size.value === title,
	})),
	rule,
	{ title: 'Rasterise', disabled: true },
	{
		title: 'Delete',
		icon: icon(trash),
		destructive: true,
		shortcut: '⌫',
	},
]);

const menus = computed((): CanonMenuBarMenu[] => [
	{
		title: 'File',
		items: [
			{ title: 'New', shortcut: '⌘N' },
			{ title: 'Open…', shortcut: '⌘O' },
			{
				title: 'Open recent',
				items: [
					{ title: 'Poster.pdf' },
					{ title: 'Letter.pdf' },
				],
			},
			rule,
			{ title: 'Close', shortcut: '⌘W' },
		],
	},
	{
		title: 'Edit',
		items: [
			{ title: 'Undo', shortcut: '⌘Z' },
			{ title: 'Redo', shortcut: '⇧⌘Z', disabled: true },
			rule,
			{ title: 'Cut', shortcut: '⌘X' },
			{ title: 'Copy', shortcut: '⌘C' },
			{ title: 'Paste', shortcut: '⌘V' },
		],
	},
	{
		title: 'View',
		items: [
			{
				title: 'Grid',
				kind: 'checkbox',
				checked: grid.value,
			},
			{
				title: 'Rulers',
				kind: 'checkbox',
				checked: rulers.value,
			},
			rule,
			{
				title: 'Zoom',
				items: [
					{ title: 'Zoom in', shortcut: '⌘+' },
					{ title: 'Zoom out', shortcut: '⌘−' },
					{ title: 'Fit', shortcut: '⌘0' },
				],
			},
		],
	},
	{ title: 'Help', items: [{ title: 'About' }] },
]);

function choose(item: CanonMenuItem) {
	chosen.value = item.title;
	if (item.title === 'Grid') grid.value = !grid.value;
	if (item.title === 'Snap') snap.value = !snap.value;
	if (item.title === 'Rulers') rulers.value = !rulers.value;
	if (item.kind === 'radio') size.value = item.title;
}

const pickSide = (index: number) => (side.value = index);
const pickEdge = (index: number) => (edge.value = index);
const setOpacity = (value: number) => (opacity.value = value);
</script>

<template>
	<CanonRows :framed="true">
		<CanonHeading text="Menus" />
		<CanonMenuBar
			aria-label="Gallery"
			:menus="menus"
			:on-select="choose"
		/>
		<CanonRow title="Dropdown" form="flush">
			<CanonMenu
				v-slot="{ trigger }"
				:items="items"
				:on-select="choose"
			>
				<CanonButton
					:ref="trigger"
					kind="cell"
					text="Actions"
					:icon="icon(chevronDown)"
				/>
			</CanonMenu>
		</CanonRow>
		<CanonRow title="Chosen" :detail="chosen" />
	</CanonRows>
	<CanonContextMenu
		class="gallery-context-area"
		tabindex="0"
		aria-label="Context area"
		:items="items"
		:on-select="choose"
	>
		<CanonCanvas :height="160"
			><GalleryArt label="Right click"
		/></CanonCanvas>
	</CanonContextMenu>
	<CanonRows :framed="true">
		<CanonHeading text="Popover" />
		<CanonRow title="Side" form="stacked">
			<CanonSegmented
				:items="sides"
				:selected="side"
				:on-change="pickSide"
			/>
		</CanonRow>
		<CanonRow title="Edge" form="stacked">
			<CanonSegmented
				:items="edges"
				:selected="edge"
				:on-change="pickEdge"
			/>
		</CanonRow>
		<CanonGrid>
			<CanonPopover
				class="gallery-popover"
				role="dialog"
				aria-label="Opacity"
				:placement="placement"
			>
				<template #trigger="{ trigger }">
					<CanonButton
						:ref="trigger"
						kind="cell"
						text="Popover"
					/>
				</template>
				<template #content="{ close }">
					<CanonRows>
						<CanonRow
							title="Opacity"
							form="stacked"
						>
							<CanonSlider
								:value="opacity"
								label="Opacity"
								:on-change="
									setOpacity
								"
							/>
						</CanonRow>
						<CanonButton
							kind="primary"
							text="Done"
							:on-click="close"
						/>
					</CanonRows>
				</template>
			</CanonPopover>
			<CanonTooltip
				v-slot="{ trigger }"
				text="Copy"
				:placement="placement"
			>
				<CanonButton
					:ref="trigger"
					kind="cell"
					label="Copy"
					:icon="icon(copy)"
				/>
			</CanonTooltip>
			<CanonTooltip
				v-slot="{ trigger }"
				text="Share"
				:placement="placement"
			>
				<CanonButton
					:ref="trigger"
					kind="cell"
					label="Share"
					:icon="icon(share)"
				/>
			</CanonTooltip>
			<CanonTooltip
				v-slot="{ trigger }"
				text="Delete"
				:placement="placement"
			>
				<CanonButton
					:ref="trigger"
					kind="cell"
					label="Delete"
					:icon="icon(trash)"
				/>
			</CanonTooltip>
		</CanonGrid>
	</CanonRows>
</template>
