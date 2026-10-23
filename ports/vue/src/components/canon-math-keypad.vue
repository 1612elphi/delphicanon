<script lang="ts">
import type { Key } from '@canon/lib/math/expression.ts';
import type { Family, Spec } from '@canon/lib/math/keypad.ts';
import type { Box } from '@canon/lib/math/typeset.ts';

interface PlacedKey {
	spec: Spec;
	face: Box;
	label: string;
	id: string;
	style: string;
}

interface Menu {
	keys: { key: Key; face: Box; label: string }[];
	family: Family;
	page: number;
	anchor: HTMLElement;
	cell: { width: number; height: number };
}
</script>

<script setup lang="ts">
import {
	computed,
	onBeforeUnmount,
	onMounted,
	ref,
	shallowRef,
	useTemplateRef,
	watch,
} from 'vue';
import { opensSlot } from '@canon/lib/math/expression.ts';
import {
	glideSpring,
	keyHeights,
	label as labelFor,
	labelShare,
	menuScale,
	nameScale,
	pages as keypadPages,
	returnDelay,
	spoken,
	tabHeights,
} from '@canon/lib/math/keypad.ts';
import { canvasMetrics } from '@canon/lib/math/measure.ts';
import { springEasing } from '@canon/lib/motion.ts';
import { Typesetter } from '@canon/lib/math/typeset.ts';
import { backspace } from '../lib/lucide.ts';
import CanonIcon from './canon-icon.vue';
import CanonMathKey from './canon-math-key.vue';
import CanonMathTabs from './canon-math-tabs.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-keypad.css';

const props = defineProps<{
	/** The first letter key, and the variable of d/dx, ∫ and lim; default x. */
	variable?: string;
	/** The short keys, for a short window. */
	short?: boolean;
	onKey?: (key: Key) => void;
	onDone?: () => void;
}>();

const progress = ref(0);
const pageWidth = ref(0);
const menu = shallowRef<Menu>();
const pager = useTemplateRef<HTMLElement>('pager');
let glide: number | undefined;
let tracking = false;

const variable = computed(() => props.variable ?? 'x');
const keyHeight = computed(() =>
	props.short ? keyHeights.short : keyHeights.regular,
);
const labelSize = computed(() => Math.round(keyHeight.value * labelShare));
const page = computed(() =>
	Math.min(Math.max(Math.round(progress.value), 0), 3),
);
const style = computed(
	() =>
		`--canon-math-key-height: ${keyHeight.value}px; --canon-math-tab-height: ${props.short ? tabHeights.short : tabHeights.regular}px`,
);

/** Faces are set once per variable and key size. */
const built = computed((): PlacedKey[][] => {
	const size = labelSize.value;
	return keypadPages(variable.value).map((specs, page) =>
		specs.map((spec) => ({
			spec,
			face: spec.menu
				? new Typesetter(
						canvasMetrics,
						size * menuScale,
					).text(spec.menu.title)
				: labelFor(
						spec.key,
						variable.value,
						size * spec.scale,
						canvasMetrics,
					),
			label:
				spec.menu?.title ??
				spoken(spec.key, variable.value),
			id: `${page}-${spec.x}-${spec.y}`,
			style: `grid-column: ${spec.x + 1} / span ${spec.w}; grid-row: ${spec.y + 1} / span ${spec.h}; --canon-math-x: ${spec.x}; --canon-math-w: ${spec.w}`,
		})),
	);
});

const pages = computed(() =>
	built.value.map((keys, index) => {
		const offset = index - progress.value;
		return {
			keys,
			index,
			away: index !== page.value,
			style: `--canon-math-offset-px: ${offset * pageWidth.value}px; --canon-math-lead: ${offset > 0 ? 1 : 0}; --canon-math-fade: ${1 - 0.7 * Math.min(1, Math.abs(offset))}`,
		};
	}),
);

const clearFace = computed(() =>
	labelFor(
		{ kind: 'clear' },
		variable.value,
		labelSize.value * 0.9,
		canvasMetrics,
	),
);

function type(key: Key, from: number) {
	closeMenu();
	props.onKey?.(key);
	if (from === 0 || !opensSlot(key)) return;
	window.setTimeout(() => {
		if (page.value !== from || glide !== undefined || tracking)
			return;
		show(0);
	}, returnDelay * 1000);
}

// paging

function show(index: number) {
	closeMenu();
	const element = pager.value;
	if (!element) return;
	const width = element.clientWidth;
	const target = Math.min(Math.max(index, 0), 3) * width;
	stopGlide();
	if (
		width === 0 ||
		matchMedia('(prefers-reduced-motion: reduce)').matches
	) {
		element.scrollLeft = target;
		return;
	}
	const from = element.scrollLeft;
	const start = performance.now();
	const omega = (2 * Math.PI) / glideSpring.response;
	const zeta = glideSpring.damping;
	const damped = omega * Math.sqrt(1 - zeta * zeta);
	element.classList.add('canon-math-keypad-pager--gliding');
	const frame = (now: number) => {
		const t = (now - start) / 1000;
		const envelope = Math.exp(-zeta * omega * t);
		const x =
			target +
			(from - target) *
				envelope *
				(Math.cos(damped * t) +
					((zeta * omega) / damped) *
						Math.sin(damped * t));
		if (t > 1.2 || (t > 0.2 && Math.abs(x - target) < 0.3)) {
			element.scrollLeft = target;
			stopGlide();
			return;
		}
		element.scrollLeft = x;
		glide = requestAnimationFrame(frame);
	};
	glide = requestAnimationFrame(frame);
}

function stopGlide() {
	if (glide !== undefined) cancelAnimationFrame(glide);
	glide = undefined;
	pager.value?.classList.remove('canon-math-keypad-pager--gliding');
}

let stopPager: (() => void) | undefined;

onMounted(() => {
	const element = pager.value!;
	const scrolled = () => {
		const width = element.clientWidth;
		if (width === 0) return;
		pageWidth.value = width;
		progress.value = element.scrollLeft / width;
	};
	const down = () => {
		tracking = true;
		stopGlide();
	};
	const up = () => (tracking = false);
	const resize = new ResizeObserver(() => {
		if (glide === undefined)
			element.scrollLeft = page.value * element.clientWidth;
		scrolled();
	});
	resize.observe(element);
	element.addEventListener('scroll', scrolled, { passive: true });
	element.addEventListener('pointerdown', down);
	element.addEventListener('wheel', down, { passive: true });
	element.addEventListener('pointerup', up);
	element.addEventListener('pointercancel', up);
	element.addEventListener('scrollend', up);
	stopPager = () => {
		resize.disconnect();
		element.removeEventListener('scroll', scrolled);
		element.removeEventListener('pointerdown', down);
		element.removeEventListener('wheel', down);
		element.removeEventListener('pointerup', up);
		element.removeEventListener('pointercancel', up);
		element.removeEventListener('scrollend', up);
	};
});

onBeforeUnmount(() => {
	stopGlide();
	stopPager?.();
});

// submenu

function openMenu(placed: PlacedKey, from: number) {
	const spec = placed.spec.menu;
	const anchor = pager.value?.querySelector<HTMLElement>(
		`[data-canon-math-key="${placed.id}"]`,
	);
	if (!spec || !anchor) return;
	const size = labelSize.value;
	menu.value = {
		keys: spec.keys.map((key) => ({
			key,
			face: labelFor(
				key,
				variable.value,
				size * nameScale,
				canvasMetrics,
			),
			label: spoken(key, variable.value),
		})),
		family: placed.spec.family,
		page: from,
		anchor,
		cell: {
			width: Math.max(64, anchor.offsetWidth / 3 + 12),
			height: keyHeight.value,
		},
	};
}

function closeMenu() {
	menu.value = undefined;
}

const menuStyle = computed(() => {
	const open = menu.value;
	if (!open) return undefined;
	const per = 3;
	const count = Math.ceil(open.keys.length / per);
	return `--canon-math-menu-cell: ${open.cell.width}px; --canon-math-key-height: ${open.cell.height}px; grid-template-rows: repeat(${count}, ${open.cell.height}px)`;
});

const panel = useTemplateRef<HTMLElement>('panel');

/** Opens over its key, growing out of the key's top edge; a touch elsewhere or Escape closes it. */
watch(
	[panel, menu],
	([panel, open], _, onCleanup) => {
		if (!panel || !open) return;
		const root = panel.parentElement!;
		const box = root.getBoundingClientRect();
		const anchor = open.anchor.getBoundingClientRect();
		const width = panel.offsetWidth;
		const height = panel.offsetHeight;
		const midX = anchor.left + anchor.width / 2 - box.left;
		const left = Math.min(
			Math.max(midX - width / 2, 6),
			box.width - 6 - width,
		);
		const top = anchor.top - box.top - height - 6;
		panel.style.insetInlineStart = `${left}px`;
		panel.style.insetBlockStart = `${top}px`;
		if (!matchMedia('(prefers-reduced-motion: reduce)').matches) {
			const dx = (midX - (left + width / 2)) * 0.6;
			const dy =
				(anchor.top - box.top - (top + height / 2)) *
				0.6;
			panel.animate(
				[
					{
						transform: `translate(${dx}px, ${dy}px) scale(0.4)`,
						opacity: 0,
					},
					{ transform: 'none', opacity: 1 },
				],
				{ duration: 340, easing: springEasing(0.74) },
			);
		}
		panel.querySelector<HTMLElement>('button')?.focus({
			preventScroll: true,
		});
		const outside = (event: PointerEvent) => {
			if (!panel.contains(event.target as Node)) closeMenu();
		};
		const escape = (event: KeyboardEvent) => {
			if (event.key !== 'Escape') return;
			event.preventDefault();
			event.stopPropagation();
			closeMenu();
			open.anchor.focus({ preventScroll: true });
		};
		document.addEventListener('pointerdown', outside, true);
		document.addEventListener('keydown', escape, true);
		onCleanup(() => {
			document.removeEventListener(
				'pointerdown',
				outside,
				true,
			);
			document.removeEventListener('keydown', escape, true);
		});
	},
	{ flush: 'post' },
);
</script>

<!--
  Maths keys on four swipeable pages (numbers and operators, functions,
  calculus, letters and constants), with delete, clear and Done beside every
  page. Hyperbolic and reciprocal trig sit in submenus. A slot key typed on a
  later page returns to the numbers, since the slot usually takes a number
  next.
-->
<template>
	<div class="canon-math-keypad" :style="style">
		<CanonMathTabs :progress="progress" :on-select="show" />
		<div ref="pager" class="canon-math-keypad-pager">
			<div
				v-for="p in pages"
				:key="p.index"
				class="canon-math-keypad-page"
				:style="p.style"
				:inert="p.away"
			>
				<template
					v-for="placed in p.keys"
					:key="placed.id"
				>
					<CanonMathKey
						v-if="placed.spec.menu"
						:face="placed.face"
						:family="placed.spec.family"
						:label="placed.label"
						:menu="true"
						:on-click="
							() =>
								openMenu(
									placed,
									p.index,
								)
						"
						:style="placed.style"
						:data-canon-math-key="placed.id"
					/>
					<CanonMathKey
						v-else
						:face="placed.face"
						:family="placed.spec.family"
						:label="placed.label"
						:on-click="
							() =>
								type(
									placed
										.spec
										.key,
									p.index,
								)
						"
						:style="placed.style"
						:data-canon-math-key="placed.id"
					/>
				</template>
			</div>
		</div>
		<div class="canon-math-keypad-spine">
			<CanonMathKey
				family="operation"
				label="Delete"
				:repeats="true"
				:on-click="() => onKey?.({ kind: 'delete' })"
				><CanonIcon :svg="backspace"
			/></CanonMathKey>
			<CanonMathKey
				:face="clearFace"
				family="clear"
				label="Clear"
				:on-click="() => onKey?.({ kind: 'clear' })"
			/>
			<CanonMathKey
				class="canon-math-keypad-done"
				family="done"
				label="Done"
				:on-click="() => onDone?.()"
				>Done</CanonMathKey
			>
		</div>
		<div
			v-if="menu"
			ref="panel"
			class="canon-math-submenu"
			:class="`canon-math-key--${menu.family}`"
			role="menu"
			:style="menuStyle"
		>
			<CanonMathKey
				v-for="(item, i) in menu.keys"
				:key="i"
				:face="item.face"
				:family="menu.family"
				:label="item.label"
				:on-click="() => type(item.key, menu!.page)"
				role="menuitem"
			/>
		</div>
	</div>
</template>
