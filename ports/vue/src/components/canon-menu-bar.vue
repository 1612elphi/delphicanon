<script setup lang="ts">
import {
	computed,
	onBeforeUnmount,
	onMounted,
	ref,
	useId,
	useTemplateRef,
	watch,
} from 'vue';
import { wrap } from '@canon/lib/menu.ts';
import { attach, hide } from '@canon/lib/popover.ts';
import CanonButton from './canon-button.vue';
import CanonGrid from './canon-grid.vue';
import CanonMenu, {
	showMenu,
	type CanonMenuEntry,
	type CanonMenuItem,
} from './canon-menu.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-menu-bar.css';

export interface CanonMenuBarMenu {
	title: string;
	items: CanonMenuEntry[];
}

const props = defineProps<{
	menus: CanonMenuBarMenu[];
	/** The item, and the index of the menu it is in. */
	onSelect?: (item: CanonMenuItem, menu: number) => void;
}>();

const id = `${useId()}-bar`;
const rootRef = useTemplateRef<HTMLElement>('root');
/** The cell in the tab order. */
const current = ref(0);
const opened = ref<number>();

const cells = computed(() =>
	props.menus.map((menu, index) => ({
		index,
		title: menu.title,
		current: index === current.value,
		open: index === opened.value,
	})),
);

function cell(index: number) {
	return rootRef.value?.querySelector<HTMLElement>(
		`[data-menu-cell="${index}"]`,
	);
}

function panel(index: number) {
	return rootRef.value?.querySelector<HTMLElement>(`#${id}-${index}`);
}

function openPanel() {
	return rootRef.value?.querySelector<HTMLElement>(
		':scope > .canon-menu:popover-open',
	);
}

// Tab out of the bar closes its menu
function focusout(event: FocusEvent) {
	const next = event.relatedTarget;
	const open = openPanel();
	const root = rootRef.value;
	if (open && root && next instanceof Node && !root.contains(next))
		hide(open);
}

let detachAll: (() => void)[] = [];

function anchorAll() {
	detachAll.forEach((detach) => detach());
	detachAll = [];
	props.menus.forEach((_, index) => {
		const menu = panel(index);
		const button = cell(index);
		if (!menu || !button) return;
		const detach = attach(menu, button, {
			placement: 'bottom-start',
			invokes: true,
			haspopup: 'menu',
		});
		const toggle = (event: ToggleEvent) => {
			if (event.newState === 'open') opened.value = index;
			else if (opened.value === index)
				opened.value = undefined;
		};
		menu.addEventListener('toggle', toggle);
		detachAll.push(() => {
			menu.removeEventListener('toggle', toggle);
			detach();
		});
	});
}

onMounted(anchorAll);
watch(() => props.menus.length, anchorAll, { flush: 'post' });
onBeforeUnmount(() => detachAll.forEach((detach) => detach()));

/** Focus a cell; if a menu is open, the cell's menu replaces it with focus left on the cell. */
function move(to: number) {
	const menu = panel(to);
	if (menu && openPanel()) showMenu(menu, 'none');
	cell(to)?.focus({ preventScroll: true });
}

function cellKey(index: number, event: KeyboardEvent) {
	const count = props.menus.length;
	const rtl = (event.currentTarget as Element).matches(':dir(rtl)');
	const menu = panel(index);
	switch (event.key) {
		case rtl ? 'ArrowLeft' : 'ArrowRight':
			move(wrap(index, 1, count));
			break;
		case rtl ? 'ArrowRight' : 'ArrowLeft':
			move(wrap(index, -1, count));
			break;
		case 'Home':
			move(0);
			break;
		case 'End':
			move(count - 1);
			break;
		// Enter and Space would toggle through popovertarget and close an open menu
		case 'ArrowDown':
		case 'Enter':
		case ' ':
			if (menu) showMenu(menu, 'first');
			break;
		case 'ArrowUp':
			if (menu) showMenu(menu, 'last');
			break;
		default:
			return;
	}
	event.preventDefault();
}

function hover(index: number, event: PointerEvent) {
	if (event.pointerType === 'touch') return;
	const open = openPanel();
	if (open && open !== panel(index)) move(index);
}

function edge(index: number, step: 1 | -1) {
	const to = wrap(index, step, props.menus.length);
	const menu = panel(to);
	if (menu) showMenu(menu, 'none');
	cell(to)?.focus({ preventScroll: true });
}

function select(index: number, item: CanonMenuItem) {
	props.onSelect?.(item, index);
}
</script>

<!--
  A row of flush cells, each opening a menu. While one is open, the
  pointer over another cell or the inline arrow keys move to its menu, as
  in the macOS menu bar. Give it an aria-label.
-->
<template>
	<div
		ref="root"
		class="canon-menu-bar"
		role="menubar"
		@focusout="focusout"
	>
		<CanonGrid class="canon-menu-bar-cells">
			<CanonButton
				v-for="c in cells"
				:key="c.index"
				class="canon-menu-bar-cell"
				:class="{ 'canon-menu-bar-cell--open': c.open }"
				role="menuitem"
				:tabindex="c.current ? '0' : '-1'"
				:data-menu-cell="c.index"
				kind="cell"
				:text="c.title"
				@keydown="cellKey(c.index, $event)"
				@pointerenter="hover(c.index, $event)"
				@focus="current = c.index"
			/>
		</CanonGrid>
		<CanonMenu
			v-for="(menu, index) in menus"
			:id="`${id}-${index}`"
			:key="index"
			:items="menu.items"
			:on-select="
				(item: CanonMenuItem) => select(index, item)
			"
			:on-edge="(step: 1 | -1) => edge(index, step)"
		/>
	</div>
</template>
