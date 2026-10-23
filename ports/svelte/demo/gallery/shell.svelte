<script lang="ts" module>
	export const pane = 'main';
	export const order = 45;
</script>

<script lang="ts">
	import CanonButton from '../../src/components/canon-button.svelte';
	import CanonCanvas from '../../src/components/canon-canvas.svelte';
	import CanonHeading from '../../src/components/canon-heading.svelte';
	import CanonMenuBar, {
		type CanonMenuBarMenu,
	} from '../../src/components/canon-menu-bar.svelte';
	import CanonPage from '../../src/components/canon-page.svelte';
	import CanonSidebar from '../../src/components/canon-sidebar.svelte';
	import CanonSidebarRow, {
		type CanonSidebarLight,
	} from '../../src/components/canon-sidebar-row.svelte';
	import CanonWindow from '../../src/components/canon-window.svelte';
	import GalleryArt from '../gallery-art.svelte';
	import { icon } from '../icon.ts';
	import aperture from 'lucide-static/icons/aperture.svg?raw';
	import camera from 'lucide-static/icons/camera.svg?raw';
	import clipboard from 'lucide-static/icons/clipboard.svg?raw';
	import keyboard from 'lucide-static/icons/keyboard.svg?raw';
	import panelLeft from 'lucide-static/icons/panel-left.svg?raw';
	import settings from 'lucide-static/icons/settings.svg?raw';
	import wrench from 'lucide-static/icons/wrench.svg?raw';
	import '../../../../demo-app/components/gallery/shell.css';

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
			items: [
				{
					title: 'Sidebar',
					kind: 'checkbox',
					checked: true,
				},
			],
		},
	];

	const modules: {
		title: string;
		svg: string;
		light?: CanonSidebarLight;
	}[] = [
		{ title: 'Clipboard', svg: clipboard, light: 'on' },
		{ title: 'Capture', svg: camera, light: 'warning' },
		{ title: 'Hotkeys', svg: keyboard, light: 'off' },
		{ title: 'Loupe', svg: aperture, light: 'on' },
	];

	let selected = $state('Toolbox');
	// undefined follows the window's width
	let collapsed = $state<true>();
	let closed = $state(false);
	let minimised = $state(false);
	let zoomed = $state(false);

	function pick(title: string, event: MouseEvent) {
		event.preventDefault();
		selected = title;
	}
</script>

<div class="gallery-shell">
	{#if closed}
		<CanonButton text="Reopen" onClick={() => (closed = false)} />
	{:else}
		<CanonWindow
			class={[
				'gallery-shell-window gallery-shell-wide',
				minimised && 'gallery-shell--minimised',
				zoomed && 'gallery-shell--zoomed',
			]}
			title="Delphi"
			framed
			onClose={() => (closed = true)}
			onMinimise={() => (minimised = !minimised)}
			onZoom={() => (zoomed = !zoomed)}
		>
			{#snippet toolbar()}
				<CanonButton
					kind="cell"
					icon={icon(panelLeft)}
					label="Sidebar"
					selected={collapsed}
					aria-pressed={collapsed
						? 'true'
						: 'false'}
					onClick={() =>
						(collapsed = collapsed
							? undefined
							: true)}
				/>
			{/snippet}
			{#snippet sidebar()}
				<CanonSidebar {collapsed} aria-label="Main">
					{#snippet hero()}
						<div class="gallery-shell-hero">
							<GalleryArt
								label="Hero"
							/>
						</div>
					{/snippet}
					<CanonSidebarRow
						title="Toolbox"
						icon={icon(wrench)}
						selected={selected ===
							'Toolbox'}
						onClick={(event) =>
							pick('Toolbox', event)}
					/>
					<CanonHeading text="Modules" />
					{#each modules as row (row.title)}
						<CanonSidebarRow
							title={row.title}
							icon={icon(row.svg)}
							light={row.light}
							selected={selected ===
								row.title}
							onClick={(event) =>
								pick(
									row.title,
									event,
								)}
						/>
					{/each}
					<CanonSidebarRow
						title="General"
						icon={icon(settings)}
						href="#general"
						selected={selected ===
							'General'}
						onClick={(event) =>
							pick('General', event)}
					/>
				</CanonSidebar>
			{/snippet}
			{#snippet main()}
				<CanonPage>
					<CanonCanvas aspect={3}
						><GalleryArt
							label={selected}
						/></CanonCanvas
					>
				</CanonPage>
			{/snippet}
		</CanonWindow>
	{/if}
	<CanonWindow
		class="gallery-shell-window gallery-shell-narrow"
		title="Narrow"
		framed
	>
		{#snippet menubar()}
			<CanonMenuBar {menus} aria-label="Narrow" />
		{/snippet}
		{#snippet sidebar()}
			<CanonSidebar aria-label="Narrow">
				<CanonSidebarRow
					title="Toolbox"
					icon={icon(wrench)}
					selected
				/>
				{#each modules.slice(0, 3) as row (row.title)}
					<CanonSidebarRow
						title={row.title}
						icon={icon(row.svg)}
						light={row.light}
					/>
				{/each}
			</CanonSidebar>
		{/snippet}
		{#snippet main()}
			<CanonPage>
				<CanonCanvas aspect={2}
					><GalleryArt
						label="Rail"
					/></CanonCanvas
				>
			</CanonPage>
		{/snippet}
	</CanonWindow>
</div>
