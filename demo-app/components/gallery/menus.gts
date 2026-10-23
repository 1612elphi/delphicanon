import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import type { TOC } from '@ember/component/template-only';
import CanonButton from '#src/components/canon-button.gts';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonContextMenu from '#src/components/canon-context-menu.gts';
import CanonGrid from '#src/components/canon-grid.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonMenu, {
	type CanonMenuEntry,
	type CanonMenuItem,
} from '#src/components/canon-menu.gts';
import CanonMenuBar, {
	type CanonMenuBarMenu,
} from '#src/components/canon-menu-bar.gts';
import CanonPopover from '#src/components/canon-popover.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonSegmented from '#src/components/canon-segmented.gts';
import CanonSlider from '#src/components/canon-slider.gts';
import CanonTooltip from '#src/components/canon-tooltip.gts';
import type { CanonPlacement } from '#src/lib/popover.ts';
import GalleryArt from '../gallery-art.gts';
import Icon from '../icon.gts';
import chevronDown from 'lucide-static/icons/chevron-down.svg?raw';
import copy from 'lucide-static/icons/copy.svg?raw';
import pencil from 'lucide-static/icons/pencil.svg?raw';
import share from 'lucide-static/icons/share.svg?raw';
import trash from 'lucide-static/icons/trash-2.svg?raw';
import './menus.css';

export const pane = 'main';
export const order = 21;

const Copy: TOC<{ Args: object }> = <template><Icon @svg={{copy}} /></template>;
const Pencil: TOC<{ Args: object }> = <template>
	<Icon @svg={{pencil}} />
</template>;
const Share: TOC<{ Args: object }> = <template>
	<Icon @svg={{share}} />
</template>;
const Trash: TOC<{ Args: object }> = <template>
	<Icon @svg={{trash}} />
</template>;

const rule = { kind: 'separator' } as const;
const sides = ['Top', 'Right', 'Bottom', 'Left'];
const edges = ['Start', 'Centre', 'End'];
const sizes = ['Small', 'Medium', 'Large'];

export default class Menus extends Component {
	@tracked chosen = '—';
	@tracked grid = true;
	@tracked snap = false;
	@tracked rulers = false;
	@tracked size = 'Medium';
	@tracked side = 2;
	@tracked edge = 0;
	@tracked opacity = 0.8;

	get placement(): CanonPlacement {
		const side = ['top', 'right', 'bottom', 'left'][this.side]!;
		const edge = ['-start', '', '-end'][this.edge]!;
		return `${side}${edge}` as CanonPlacement;
	}

	get items(): CanonMenuEntry[] {
		return [
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
				checked: this.grid,
				shortcut: "⌘'",
			},
			{ title: 'Snap', kind: 'checkbox', checked: this.snap },
			rule,
			...sizes.map((title) => ({
				title,
				kind: 'radio' as const,
				checked: this.size === title,
			})),
			rule,
			{ title: 'Rasterise', disabled: true },
			{
				title: 'Delete',
				icon: Trash,
				destructive: true,
				shortcut: '⌫',
			},
		];
	}

	get menus(): CanonMenuBarMenu[] {
		return [
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
						checked: this.grid,
					},
					{
						title: 'Rulers',
						kind: 'checkbox',
						checked: this.rulers,
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
		];
	}

	choose = (item: CanonMenuItem) => {
		this.chosen = item.title;
		if (item.title === 'Grid') this.grid = !this.grid;
		if (item.title === 'Snap') this.snap = !this.snap;
		if (item.title === 'Rulers') this.rulers = !this.rulers;
		if (item.kind === 'radio') this.size = item.title;
	};

	pickSide = (index: number) => {
		this.side = index;
	};

	pickEdge = (index: number) => {
		this.edge = index;
	};

	setOpacity = (value: number) => {
		this.opacity = value;
	};

	<template>
		<CanonRows @framed={{true}}>
			<CanonHeading @text="Menus" />
			<CanonMenuBar
				aria-label="Gallery"
				@menus={{this.menus}}
				@onSelect={{this.choose}}
			/>
			<CanonRow @title="Dropdown" @form="flush">
				<CanonMenu
					@items={{this.items}}
					@onSelect={{this.choose}}
					as |menu|
				>
					<CanonButton
						{{menu.trigger}}
						@kind="cell"
						@text="Actions"
						@icon={{component
							Icon
							svg=chevronDown
						}}
					/>
				</CanonMenu>
			</CanonRow>
			<CanonRow @title="Chosen" @detail={{this.chosen}} />
		</CanonRows>
		<CanonContextMenu
			class="gallery-context-area"
			tabindex="0"
			aria-label="Context area"
			@items={{this.items}}
			@onSelect={{this.choose}}
		>
			<CanonCanvas @height={{160}}><GalleryArt
					@label="Right click"
				/></CanonCanvas>
		</CanonContextMenu>
		<CanonRows @framed={{true}}>
			<CanonHeading @text="Popover" />
			<CanonRow @title="Side" @form="stacked">
				<CanonSegmented
					@items={{sides}}
					@selected={{this.side}}
					@onChange={{this.pickSide}}
				/>
			</CanonRow>
			<CanonRow @title="Edge" @form="stacked">
				<CanonSegmented
					@items={{edges}}
					@selected={{this.edge}}
					@onChange={{this.pickEdge}}
				/>
			</CanonRow>
			<CanonGrid>
				<CanonPopover
					class="gallery-popover"
					role="dialog"
					aria-label="Opacity"
					@placement={{this.placement}}
				>
					<:trigger as |popover|>
						<CanonButton
							{{popover.trigger}}
							@kind="cell"
							@text="Popover"
						/>
					</:trigger>
					<:content as |popover|>
						<CanonRows>
							<CanonRow
								@title="Opacity"
								@form="stacked"
							>
								<CanonSlider
									@value={{this.opacity}}
									@label="Opacity"
									@onChange={{this.setOpacity}}
								/>
							</CanonRow>
							<CanonButton
								@kind="primary"
								@text="Done"
								@onClick={{popover.close}}
							/>
						</CanonRows>
					</:content>
				</CanonPopover>
				<CanonTooltip
					@text="Copy"
					@placement={{this.placement}}
					as |tip|
				>
					<CanonButton
						{{tip.trigger}}
						@kind="cell"
						@label="Copy"
						@icon={{component
							Icon
							svg=copy
						}}
					/>
				</CanonTooltip>
				<CanonTooltip
					@text="Share"
					@placement={{this.placement}}
					as |tip|
				>
					<CanonButton
						{{tip.trigger}}
						@kind="cell"
						@label="Share"
						@icon={{component
							Icon
							svg=share
						}}
					/>
				</CanonTooltip>
				<CanonTooltip
					@text="Delete"
					@placement={{this.placement}}
					as |tip|
				>
					<CanonButton
						{{tip.trigger}}
						@kind="cell"
						@label="Delete"
						@icon={{component
							Icon
							svg=trash
						}}
					/>
				</CanonTooltip>
			</CanonGrid>
		</CanonRows>
	</template>
}
