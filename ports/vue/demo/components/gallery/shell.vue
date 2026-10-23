<script lang="ts">
export const pane = 'main';
export const order = 45;
</script>

<script setup lang="ts">
import { ref } from 'vue';
import CanonButton from '../../../src/components/canon-button.vue';
import CanonCanvas from '../../../src/components/canon-canvas.vue';
import CanonHeading from '../../../src/components/canon-heading.vue';
import CanonMenuBar, {
	type CanonMenuBarMenu,
} from '../../../src/components/canon-menu-bar.vue';
import CanonPage from '../../../src/components/canon-page.vue';
import CanonSidebar from '../../../src/components/canon-sidebar.vue';
import CanonSidebarRow from '../../../src/components/canon-sidebar-row.vue';
import CanonWindow from '../../../src/components/canon-window.vue';
import GalleryArt from '../gallery-art.vue';
import { icon } from '../icon.ts';
import aperture from 'lucide-static/icons/aperture.svg?raw';
import camera from 'lucide-static/icons/camera.svg?raw';
import clipboard from 'lucide-static/icons/clipboard.svg?raw';
import keyboard from 'lucide-static/icons/keyboard.svg?raw';
import panelLeft from 'lucide-static/icons/panel-left.svg?raw';
import settings from 'lucide-static/icons/settings.svg?raw';
import wrench from 'lucide-static/icons/wrench.svg?raw';
import '../../../../../demo-app/components/gallery/shell.css';

const menus: CanonMenuBarMenu[] = [
	{
		title: 'File',
		items: [
			{ title: 'New', shortcut: '⌘N' },
			{ title: 'Close', shortcut: '⌘W' },
		],
	},
	{
		title: 'Edit',
		items: [
			{ title: 'Undo', shortcut: '⌘Z' },
			{ title: 'Copy', shortcut: '⌘C' },
		],
	},
	{
		title: 'View',
		items: [{ title: 'Sidebar', kind: 'checkbox', checked: true }],
	},
];

const selected = ref('Toolbox');
// undefined follows the window's width
const collapsed = ref<true>();
const closed = ref(false);
const minimised = ref(false);
const zoomed = ref(false);

function pick(title: string, event: MouseEvent) {
	event.preventDefault();
	selected.value = title;
}
const toggle = () => (collapsed.value = collapsed.value ? undefined : true);
const close = () => (closed.value = true);
const reopen = () => (closed.value = false);
const minimise = () => (minimised.value = !minimised.value);
const zoom = () => (zoomed.value = !zoomed.value);
</script>

<template>
	<div class="gallery-shell">
		<CanonButton v-if="closed" text="Reopen" :on-click="reopen" />
		<CanonWindow
			v-else
			class="gallery-shell-window gallery-shell-wide"
			:class="{
				'gallery-shell--minimised': minimised,
				'gallery-shell--zoomed': zoomed,
			}"
			title="Delphi"
			:framed="true"
			:on-close="close"
			:on-minimise="minimise"
			:on-zoom="zoom"
		>
			<template #toolbar>
				<CanonButton
					kind="cell"
					:icon="icon(panelLeft)"
					label="Sidebar"
					:selected="collapsed"
					:aria-pressed="
						collapsed ? 'true' : 'false'
					"
					:on-click="toggle"
				/>
			</template>
			<template #sidebar>
				<CanonSidebar
					:collapsed="collapsed"
					aria-label="Main"
				>
					<template #hero>
						<div class="gallery-shell-hero">
							<GalleryArt
								label="Hero"
							/>
						</div>
					</template>
					<template #default>
						<CanonSidebarRow
							title="Toolbox"
							:icon="icon(wrench)"
							:selected="
								selected ===
								'Toolbox'
							"
							:on-click="
								(
									e: MouseEvent,
								) =>
									pick(
										'Toolbox',
										e,
									)
							"
						/>
						<CanonHeading text="Modules" />
						<CanonSidebarRow
							title="Clipboard"
							:icon="icon(clipboard)"
							light="on"
							:selected="
								selected ===
								'Clipboard'
							"
							:on-click="
								(
									e: MouseEvent,
								) =>
									pick(
										'Clipboard',
										e,
									)
							"
						/>
						<CanonSidebarRow
							title="Capture"
							:icon="icon(camera)"
							light="warning"
							:selected="
								selected ===
								'Capture'
							"
							:on-click="
								(
									e: MouseEvent,
								) =>
									pick(
										'Capture',
										e,
									)
							"
						/>
						<CanonSidebarRow
							title="Hotkeys"
							:icon="icon(keyboard)"
							light="off"
							:selected="
								selected ===
								'Hotkeys'
							"
							:on-click="
								(
									e: MouseEvent,
								) =>
									pick(
										'Hotkeys',
										e,
									)
							"
						/>
						<CanonSidebarRow
							title="Loupe"
							:icon="icon(aperture)"
							light="on"
							:selected="
								selected ===
								'Loupe'
							"
							:on-click="
								(
									e: MouseEvent,
								) =>
									pick(
										'Loupe',
										e,
									)
							"
						/>
						<CanonSidebarRow
							title="General"
							:icon="icon(settings)"
							href="#general"
							:selected="
								selected ===
								'General'
							"
							:on-click="
								(
									e: MouseEvent,
								) =>
									pick(
										'General',
										e,
									)
							"
						/>
					</template>
				</CanonSidebar>
			</template>
			<template #main>
				<CanonPage>
					<CanonCanvas :aspect="3"
						><GalleryArt :label="selected"
					/></CanonCanvas>
				</CanonPage>
			</template>
		</CanonWindow>
		<CanonWindow
			class="gallery-shell-window gallery-shell-narrow"
			title="Narrow"
			:framed="true"
		>
			<template #menubar>
				<CanonMenuBar
					:menus="menus"
					aria-label="Narrow"
				/>
			</template>
			<template #sidebar>
				<CanonSidebar aria-label="Narrow">
					<CanonSidebarRow
						title="Toolbox"
						:icon="icon(wrench)"
						:selected="true"
					/>
					<CanonSidebarRow
						title="Clipboard"
						:icon="icon(clipboard)"
						light="on"
					/>
					<CanonSidebarRow
						title="Capture"
						:icon="icon(camera)"
						light="warning"
					/>
					<CanonSidebarRow
						title="Hotkeys"
						:icon="icon(keyboard)"
						light="off"
					/>
				</CanonSidebar>
			</template>
			<template #main>
				<CanonPage>
					<CanonCanvas :aspect="2"
						><GalleryArt label="Rail"
					/></CanonCanvas>
				</CanonPage>
			</template>
		</CanonWindow>
	</div>
</template>
