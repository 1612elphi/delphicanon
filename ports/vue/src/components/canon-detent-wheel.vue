<script lang="ts">
/** Pointer travel in px under which a release is a tap. */
const tapSlop = 6;
/** Wheel events further apart than this end a wheel turn. */
const wheelRestMs = 120;

function reducedMotion() {
	return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}
</script>

<script setup lang="ts">
import {
	computed,
	onBeforeUnmount,
	onMounted,
	ref,
	useTemplateRef,
	watch,
} from 'vue';
import {
	advance,
	detent,
	drum,
	goal,
	isSettled,
	placement,
	tappedRows,
	wrapped,
	type DetentMotion,
	type DetentRange,
} from '@canon/lib/detent-wheel.ts';
import { vGrabPan } from '../lib/grab-pan.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-detent-wheel.css';

const props = defineProps<{
	count: number;
	/** The centred row. A change turns the wheel there the shorter way round. */
	selected: number;
	/** Default 40. */
	rowHeight?: number;
	/** The centred row changed, by a drag, a fling, a tap, the wheel or the keys, once per row crossed. */
	onSelect?: (index: number) => void;
	/** Accessible reading of a row. */
	text?: (index: number) => string;
	label?: string;
	labelledBy?: string;
}>();

defineSlots<{
	/** Paints one row: its index and `focus`, 1 on the centre line and 0 a row or more away. */
	default?: (props: { index: number; focus: number }) => unknown;
}>();

function clampIndex(index: number) {
	return props.count === 0
		? 0
		: Math.min(Math.max(index, 0), props.count - 1);
}

const selected = ref(clampIndex(props.selected));
const position = ref(selected.value);
const height = ref(0);
let motion: DetentMotion = {
	position: selected.value,
	velocity: 0,
	target: selected.value,
};
let asked = props.selected;
let frameId: number | undefined;
let last = 0;
let dragging = false;
let dragState = {
	startY: 0,
	lastY: 0,
	travel: 0,
	samples: [] as [number, number][],
};
let wheelTimer: number | undefined;

const rowHeight = computed(() => props.rowHeight ?? 40);
const geometry = computed(() => drum(height.value, rowHeight.value));
const loops = computed(() => props.count > geometry.value.fitting);
const range = computed<DetentRange>(() =>
	loops.value ? undefined : [0, Math.max(props.count - 1, 0)],
);

const rows = computed(() => {
	const { count } = props;
	if (count === 0 || height.value === 0) return [];
	const { radius, step } = geometry.value;
	const half = Math.floor(detent.reach / step) + 1;
	const centre = Math.round(position.value);
	const list = [];
	for (let index = centre - half; index <= centre + half; index++) {
		if (!loops.value && (index < 0 || index >= count)) continue;
		const offset = index - position.value;
		if (Math.abs(offset) * step > detent.reach) continue;
		const { y, scaleY, opacity, focus } = placement(
			offset,
			step,
			radius,
		);
		list.push({
			key: index,
			index: wrapped(index, count),
			focus,
			style: {
				transform: `translateY(${y}px) scaleY(${scaleY})`,
				opacity,
			},
		});
	}
	return list;
});

const valueText = computed(() =>
	props.count > 0 ? props.text?.(selected.value) : undefined,
);

function place(to: number) {
	position.value = to;
	const nearest = wrapped(Math.round(to), props.count);
	if (props.count === 0 || nearest === selected.value) return;
	selected.value = nearest;
	asked = nearest;
	props.onSelect?.(nearest);
}

function run() {
	if (frameId !== undefined) return;
	last = performance.now();
	const frame = (now: number) => {
		const seconds = Math.min((now - last) / 1000, 1 / 30);
		last = now;
		motion = advance(motion, seconds, range.value);
		place(motion.position);
		if (isSettled(motion)) frameId = undefined;
		else frameId = requestAnimationFrame(frame);
	};
	frameId = requestAnimationFrame(frame);
}

function stop() {
	if (frameId !== undefined) cancelAnimationFrame(frameId);
	frameId = undefined;
}

/** Turns to `index`, the shorter way round when the wheel loops. */
function select(index: number, animated: boolean) {
	if (props.count === 0) return;
	const to = goal(motion.position, index, props.count, loops.value);
	if (animated && !reducedMotion()) {
		motion = { ...motion, target: to };
		run();
	} else {
		stop();
		motion = { position: to, velocity: 0, target: to };
		place(to);
	}
}

/** Moves by `rows` of drag, pulled short past the ends. */
function drag(by: number) {
	const bounds = range.value;
	const at = motion.position;
	const outside = bounds && (at < bounds[0] || at > bounds[1]);
	motion = {
		position: at + (outside ? by * detent.rubber : by),
		velocity: 0,
	};
	place(motion.position);
}

function release(velocity: number) {
	motion = { ...motion, velocity, target: undefined };
	run();
}

const root = useTemplateRef<HTMLElement>('root');
let unmeasure: (() => void) | undefined;
onMounted(() => {
	const element = root.value!;
	const observer = new ResizeObserver(([entry]) => {
		height.value = entry?.contentRect.height ?? 0;
	});
	observer.observe(element);
	const wheel = (event: WheelEvent) => {
		if (props.count === 0) return;
		event.preventDefault();
		stop();
		drag(
			event.deltaMode === WheelEvent.DOM_DELTA_PIXEL
				? event.deltaY / rowHeight.value
				: Math.sign(event.deltaY),
		);
		window.clearTimeout(wheelTimer);
		wheelTimer = window.setTimeout(() => release(0), wheelRestMs);
	};
	element.addEventListener('wheel', wheel, { passive: false });
	unmeasure = () => {
		observer.disconnect();
		element.removeEventListener('wheel', wheel);
	};
});

let knownCount = props.count;
watch([() => props.count, () => props.selected], ([count, wanted]) => {
	if (count !== knownCount) {
		knownCount = count;
		asked = wanted;
		const index = clampIndex(wanted);
		stop();
		selected.value = index;
		motion = { position: index, velocity: 0, target: index };
		position.value = index;
	} else if (wanted !== asked) {
		asked = wanted;
		if (wanted !== selected.value && !dragging)
			select(clampIndex(wanted), true);
	}
});

const pan = {
	grabs: () => props.count > 0,
	onBegin(event: PointerEvent) {
		stop();
		dragging = true;
		dragState = {
			startY: event.clientY,
			lastY: event.clientY,
			travel: 0,
			samples: [[event.timeStamp, event.clientY]],
		};
	},
	onMove(event: PointerEvent) {
		const dy = event.clientY - dragState.lastY;
		dragState.lastY = event.clientY;
		dragState.travel = Math.max(
			dragState.travel,
			Math.abs(event.clientY - dragState.startY),
		);
		dragState.samples = [
			...dragState.samples.filter(
				([time]) => event.timeStamp - time < 100,
			),
			[event.timeStamp, event.clientY],
		];
		drag(-dy / rowHeight.value);
	},
	onEnd(event: PointerEvent) {
		dragging = false;
		if (dragState.travel < tapSlop) {
			tap(event);
			return;
		}
		const [first] = dragState.samples;
		const seconds = first ? (event.timeStamp - first[0]) / 1000 : 0;
		const pxPerSecond =
			first && seconds > 0
				? (event.clientY - first[1]) / seconds
				: 0;
		const speed =
			(-pxPerSecond / rowHeight.value) * detent.flingCarry;
		release(
			Math.min(
				Math.max(speed, -detent.flingLimit),
				detent.flingLimit,
			),
		);
	},
};

function tap(event: PointerEvent) {
	const box = (
		event.currentTarget as HTMLElement
	).getBoundingClientRect();
	const { radius, step } = geometry.value;
	const by = tappedRows(
		event.clientY - (box.top + box.height / 2),
		radius,
		step,
	);
	let to = Math.round(motion.position) + by;
	const bounds = range.value;
	if (bounds) to = Math.min(Math.max(to, bounds[0]), bounds[1]);
	motion = { ...motion, target: to };
	run();
}

function key(event: KeyboardEvent) {
	const { count } = props;
	if (count === 0) return;
	const lastIndex = count - 1;
	const next: Record<string, number> = {
		ArrowDown: selected.value + 1,
		ArrowRight: selected.value + 1,
		ArrowUp: selected.value - 1,
		ArrowLeft: selected.value - 1,
		Home: 0,
		End: lastIndex,
	};
	const to = next[event.key];
	if (to === undefined) return;
	event.preventDefault();
	if (!loops.value && (to < 0 || to > lastIndex)) return;
	select(wrapped(to, count), true);
}

onBeforeUnmount(() => {
	unmeasure?.();
	stop();
	window.clearTimeout(wheelTimer);
});
</script>

<!--
  Rows on a drum, turned by a vertical drag or the mouse wheel, with inertia;
  it comes to rest on a row, and the centred row is the selection. Rows
  flatten and fade with their angle from the centre. It loops when there are
  more rows than fit; otherwise the ends pull back like rubber.
-->
<template>
	<div
		ref="root"
		v-grab-pan="pan"
		class="canon-detent-wheel"
		:style="{ '--canon-detent-row': `${rowHeight}px` }"
		role="slider"
		tabindex="0"
		aria-orientation="vertical"
		aria-valuemin="0"
		:aria-valuemax="Math.max(count - 1, 0)"
		:aria-valuenow="selected"
		:aria-valuetext="valueText"
		:aria-label="label"
		:aria-labelledby="labelledBy"
		@keydown="key"
	>
		<div
			v-for="row in rows"
			:key="row.key"
			class="canon-detent-wheel-slot"
			:style="row.style"
			aria-hidden="true"
		>
			<slot :index="row.index" :focus="row.focus" />
		</div>
	</div>
</template>
