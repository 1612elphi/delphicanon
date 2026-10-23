<script lang="ts" module>
	export const pane = 'main';
	export const order = 21;
</script>

<script lang="ts">
	import CanonButton from '../../src/components/canon-button.svelte';
	import CanonCanvas from '../../src/components/canon-canvas.svelte';
	import CanonContextMenu from '../../src/components/canon-context-menu.svelte';
	import CanonGrid from '../../src/components/canon-grid.svelte';
	import CanonHeading from '../../src/components/canon-heading.svelte';
	import CanonMenu, {
		type CanonMenuEntry,
		type CanonMenuItem,
	} from '../../src/components/canon-menu.svelte';
	import CanonMenuBar, {
		type CanonMenuBarMenu,
	} from '../../src/components/canon-menu-bar.svelte';
	import CanonPopover from '../../src/components/canon-popover.svelte';
	import CanonRow from '../../src/components/canon-row.svelte';
	import CanonRows from '../../src/components/canon-rows.svelte';
	import CanonSegmented from '../../src/components/canon-segmented.svelte';
	import CanonSlider from '../../src/components/canon-slider.svelte';
	import CanonTooltip from '../../src/components/canon-tooltip.svelte';
	import type { CanonPlacement } from '@canon/lib/popover.ts';
	import GalleryArt from '../gallery-art.svelte';
	import { icon } from '../icon.ts';
	import chevronDown from 'lucide-static/icons/chevron-down.svg?raw';
	import copy from 'lucide-static/icons/copy.svg?raw';
	import pencil from 'lucide-static/icons/pencil.svg?raw';
	import share from 'lucide-static/icons/share.svg?raw';
	import trash from 'lucide-static/icons/trash-2.svg?raw';
	import '../../../../demo-app/components/gallery/menus.css';

	const Copy = icon(copy);
	const Pencil = icon(pencil);
	const Share = icon(share);
	const Trash = icon(trash);

	const rule = { kind: 'separator' } as const;
	const sides = ['Top', 'Right', 'Bottom', 'Left'];
	const edges = ['Start', 'Centre', 'End'];
	const sizes = ['Small', 'Medium', 'Large'];

	let chosen = $state('—');
	let grid = $state(true);
	let snap = $state(false);
	let rulers = $state(false);
	let size = $state('Medium');
	let side = $state(2);
	let edge = $state(0);
	let opacity = $state(0.8);

	const placement = $derived(
		`${['top', 'right', 'bottom', 'left'][side]!}${['-start', '', '-end'][edge]!}` as CanonPlacement,
	);

	const items: CanonMenuEntry[] = $derived([
		{ title: 'Duplicate', icon: Copy, shortcut: '⌘D' },
		{ title: 'Rename…', icon: Pencil },
		{
			title: 'Share',
			icon: Share,
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
			checked: grid,
			shortcut: "⌘'",
		},
		{ title: 'Snap', kind: 'checkbox', checked: snap },
		rule,
		...sizes.map((title) => ({
			title,
			kind: 'radio' as const,
			checked: size === title,
		})),
		rule,
		{ title: 'Rasterise', disabled: true },
		{
			title: 'Delete',
			icon: Trash,
			destructive: true,
			shortcut: '⌫',
		},
	]);

	const menus: CanonMenuBarMenu[] = $derived([
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
				{
					title: 'Redo',
					shortcut: '⇧⌘Z',
					disabled: true,
				},
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
					checked: grid,
				},
				{
					title: 'Rulers',
					kind: 'checkbox',
					checked: rulers,
				},
				rule,
				{
					title: 'Zoom',
					items: [
						{
							title: 'Zoom in',
							shortcut: '⌘+',
						},
						{
							title: 'Zoom out',
							shortcut: '⌘−',
						},
						{
							title: 'Fit',
							shortcut: '⌘0',
						},
					],
				},
			],
		},
		{ title: 'Help', items: [{ title: 'About' }] },
	]);

	function choose(item: CanonMenuItem) {
		chosen = item.title;
		if (item.title === 'Grid') grid = !grid;
		if (item.title === 'Snap') snap = !snap;
		if (item.title === 'Rulers') rulers = !rulers;
		if (item.kind === 'radio') size = item.title;
	}
</script>

<CanonRows framed>
	<CanonHeading text="Menus" />
	<CanonMenuBar aria-label="Gallery" {menus} onSelect={choose} />
	<CanonRow title="Dropdown" form="flush">
		<CanonMenu {items} onSelect={choose}>
			{#snippet children(menu)}
				<CanonButton
					{@attach menu.trigger}
					kind="cell"
					text="Actions"
					icon={icon(chevronDown)}
				/>
			{/snippet}
		</CanonMenu>
	</CanonRow>
	<CanonRow title="Chosen" detail={chosen} />
</CanonRows>
<CanonContextMenu
	class="gallery-context-area"
	tabindex={0}
	aria-label="Context area"
	{items}
	onSelect={choose}
>
	<CanonCanvas height={160}
		><GalleryArt label="Right click" /></CanonCanvas
	>
</CanonContextMenu>
<CanonRows framed>
	<CanonHeading text="Popover" />
	<CanonRow title="Side" form="stacked">
		<CanonSegmented
			items={sides}
			selected={side}
			onChange={(index) => (side = index)}
		/>
	</CanonRow>
	<CanonRow title="Edge" form="stacked">
		<CanonSegmented
			items={edges}
			selected={edge}
			onChange={(index) => (edge = index)}
		/>
	</CanonRow>
	<CanonGrid>
		<CanonPopover
			class="gallery-popover"
			role="dialog"
			aria-label="Opacity"
			{placement}
		>
			{#snippet trigger(popover)}
				<CanonButton
					{@attach popover.trigger}
					kind="cell"
					text="Popover"
				/>
			{/snippet}
			{#snippet content(popover)}
				<CanonRows>
					<CanonRow
						title="Opacity"
						form="stacked"
					>
						<CanonSlider
							value={opacity}
							label="Opacity"
							onChange={(value) =>
								(opacity =
									value)}
						/>
					</CanonRow>
					<CanonButton
						kind="primary"
						text="Done"
						onClick={popover.close}
					/>
				</CanonRows>
			{/snippet}
		</CanonPopover>
		<CanonTooltip text="Copy" {placement}>
			{#snippet children(tip)}
				<CanonButton
					{@attach tip.trigger}
					kind="cell"
					label="Copy"
					icon={icon(copy)}
				/>
			{/snippet}
		</CanonTooltip>
		<CanonTooltip text="Share" {placement}>
			{#snippet children(tip)}
				<CanonButton
					{@attach tip.trigger}
					kind="cell"
					label="Share"
					icon={icon(share)}
				/>
			{/snippet}
		</CanonTooltip>
		<CanonTooltip text="Delete" {placement}>
			{#snippet children(tip)}
				<CanonButton
					{@attach tip.trigger}
					kind="cell"
					label="Delete"
					icon={icon(trash)}
				/>
			{/snippet}
		</CanonTooltip>
	</CanonGrid>
</CanonRows>
