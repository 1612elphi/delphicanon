<script lang="ts" module>
	/** Pointer travel in px under which a release is a tap. */
	const tapSlop = 6;
	/** Wheel events further apart than this end a wheel turn. */
	const wheelRestMs = 120;

	function reducedMotion() {
		return window.matchMedia('(prefers-reduced-motion: reduce)')
			.matches;
	}
</script>

<script lang="ts">
	import { onDestroy, untrack, type Snippet } from 'svelte';
	import type { Attachment } from 'svelte/attachments';
	import type { HTMLAttributes } from 'svelte/elements';
	import { grabPan } from '../lib/grab-pan.ts';
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
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-detent-wheel.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'children'
	> {
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
		/** Paints one row: its index and `focus`, 1 on the centre line and 0 a row or more away. */
		children?: Snippet<[index: number, focus: number]>;
	}

	let {
		count,
		selected: asked,
		rowHeight = 40,
		onSelect,
		text,
		label,
		labelledBy,
		children,
		class: className,
		onkeydown,
		...rest
	}: Props = $props();

	const clampIndex = (index: number) =>
		count === 0 ? 0 : Math.min(Math.max(index, 0), count - 1);

	let selected = $state(untrack(() => clampIndex(asked)));
	let position = $state(untrack(() => selected));
	let height = $state(0);
	let motion: DetentMotion = untrack(() => ({
		position: selected,
		velocity: 0,
		target: selected,
	}));
	let lastCount = untrack(() => count);
	let lastAsked = untrack(() => asked);
	let frame: number | undefined;
	let last = 0;
	let dragging = false;
	let drag = {
		startY: 0,
		lastY: 0,
		travel: 0,
		samples: [] as [number, number][],
	};
	let wheelTimer: number | undefined;

	const geometry = $derived(drum(height, rowHeight));
	const loops = $derived(count > geometry.fitting);
	const range: DetentRange = $derived(
		loops ? undefined : [0, Math.max(count - 1, 0)],
	);

	const rows = $derived.by(() => {
		if (count === 0 || height === 0) return [];
		const { radius, step } = geometry;
		const half = Math.floor(detent.reach / step) + 1;
		const centre = Math.round(position);
		const rows = [];
		for (
			let index = centre - half;
			index <= centre + half;
			index++
		) {
			if (!loops && (index < 0 || index >= count)) continue;
			const offset = index - position;
			if (Math.abs(offset) * step > detent.reach) continue;
			const { y, scaleY, opacity, focus } = placement(
				offset,
				step,
				radius,
			);
			rows.push({
				key: index,
				index: wrapped(index, count),
				focus,
				style: `transform: translateY(${y}px) scaleY(${scaleY}); opacity: ${opacity}`,
			});
		}
		return rows;
	});

	const valueText = $derived(count > 0 ? text?.(selected) : undefined);

	function place(to: number) {
		position = to;
		const nearest = wrapped(Math.round(to), count);
		if (count === 0 || nearest === selected) return;
		selected = nearest;
		lastAsked = nearest;
		onSelect?.(nearest);
	}

	function run() {
		if (frame !== undefined) return;
		last = performance.now();
		const step = (now: number) => {
			const seconds = Math.min((now - last) / 1000, 1 / 30);
			last = now;
			motion = advance(motion, seconds, range);
			place(motion.position);
			if (isSettled(motion)) frame = undefined;
			else frame = requestAnimationFrame(step);
		};
		frame = requestAnimationFrame(step);
	}

	function stop() {
		if (frame !== undefined) cancelAnimationFrame(frame);
		frame = undefined;
	}

	/** Turns to `index`, the shorter way round when the wheel loops. */
	function select(index: number, animated: boolean) {
		if (count === 0) return;
		const to = goal(motion.position, index, count, loops);
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
	function dragBy(rows: number) {
		const { position: at } = motion;
		const outside = range && (at < range[0] || at > range[1]);
		motion = {
			position: at + (outside ? rows * detent.rubber : rows),
			velocity: 0,
		};
		place(motion.position);
	}

	function release(velocity: number) {
		motion = { ...motion, velocity, target: undefined };
		run();
	}

	const measure: Attachment<HTMLElement> = (element) => {
		const observer = new ResizeObserver(([entry]) => {
			height = entry?.contentRect.height ?? 0;
		});
		observer.observe(element);
		const wheel = (event: WheelEvent) => {
			if (count === 0) return;
			event.preventDefault();
			stop();
			dragBy(
				event.deltaMode === WheelEvent.DOM_DELTA_PIXEL
					? event.deltaY / rowHeight
					: Math.sign(event.deltaY),
			);
			window.clearTimeout(wheelTimer);
			wheelTimer = window.setTimeout(
				() => release(0),
				wheelRestMs,
			);
		};
		element.addEventListener('wheel', wheel, { passive: false });
		return () => {
			observer.disconnect();
			element.removeEventListener('wheel', wheel);
		};
	};

	// re-runs when count or selected change
	const follow: Attachment<HTMLElement> = () => {
		const [nextCount, nextAsked] = [count, asked];
		untrack(() => {
			if (nextCount !== lastCount) {
				lastCount = nextCount;
				lastAsked = nextAsked;
				const index = clampIndex(nextAsked);
				stop();
				selected = index;
				motion = {
					position: index,
					velocity: 0,
					target: index,
				};
				position = index;
			} else if (nextAsked !== lastAsked) {
				lastAsked = nextAsked;
				if (nextAsked !== selected && !dragging)
					select(clampIndex(nextAsked), true);
			}
		});
	};

	const grabs = () => count > 0;

	function begin(event: PointerEvent) {
		stop();
		dragging = true;
		drag = {
			startY: event.clientY,
			lastY: event.clientY,
			travel: 0,
			samples: [[event.timeStamp, event.clientY]],
		};
	}

	function move(event: PointerEvent) {
		const dy = event.clientY - drag.lastY;
		drag.lastY = event.clientY;
		drag.travel = Math.max(
			drag.travel,
			Math.abs(event.clientY - drag.startY),
		);
		drag.samples = [
			...drag.samples.filter(
				([time]) => event.timeStamp - time < 100,
			),
			[event.timeStamp, event.clientY],
		];
		dragBy(-dy / rowHeight);
	}

	function end(event: PointerEvent) {
		dragging = false;
		if (drag.travel < tapSlop) {
			tap(event);
			return;
		}
		const [first] = drag.samples;
		const seconds = first ? (event.timeStamp - first[0]) / 1000 : 0;
		const pxPerSecond =
			first && seconds > 0
				? (event.clientY - first[1]) / seconds
				: 0;
		const speed = (-pxPerSecond / rowHeight) * detent.flingCarry;
		release(
			Math.min(
				Math.max(speed, -detent.flingLimit),
				detent.flingLimit,
			),
		);
	}

	function tap(event: PointerEvent) {
		const box = (
			event.currentTarget as HTMLElement
		).getBoundingClientRect();
		const { radius, step } = geometry;
		const rows = tappedRows(
			event.clientY - (box.top + box.height / 2),
			radius,
			step,
		);
		let to = Math.round(motion.position) + rows;
		if (range) to = Math.min(Math.max(to, range[0]), range[1]);
		motion = { ...motion, target: to };
		run();
	}

	function key(event: KeyboardEvent & { currentTarget: HTMLDivElement }) {
		onkeydown?.(event);
		if (count === 0) return;
		const lastIndex = count - 1;
		const next: Record<string, number> = {
			ArrowDown: selected + 1,
			ArrowRight: selected + 1,
			ArrowUp: selected - 1,
			ArrowLeft: selected - 1,
			Home: 0,
			End: lastIndex,
		};
		const to = next[event.key];
		if (to === undefined) return;
		event.preventDefault();
		if (!loops && (to < 0 || to > lastIndex)) return;
		select(wrapped(to, count), true);
	}

	onDestroy(() => {
		stop();
		clearTimeout(wheelTimer);
	});
</script>

<!--
  @component
  Rows on a drum, turned by a vertical drag or the mouse wheel, with inertia;
  it comes to rest on a row, and the centred row is the selection. Rows
  flatten and fade with their angle from the centre. It loops when there are
  more rows than fit; otherwise the ends pull back like rubber.
-->
<div
	class={['canon-detent-wheel', className]}
	style="--canon-detent-row: {rowHeight}px"
	role="slider"
	tabindex="0"
	aria-orientation="vertical"
	aria-valuemin={0}
	aria-valuemax={Math.max(count - 1, 0)}
	aria-valuenow={selected}
	aria-valuetext={valueText}
	aria-label={label}
	aria-labelledby={labelledBy}
	onkeydown={key}
	{@attach measure}
	{@attach follow}
	{@attach grabPan({ grabs, onBegin: begin, onMove: move, onEnd: end })}
	{...rest}
>
	{#each rows as row (row.key)}
		<div
			class="canon-detent-wheel-slot"
			style={row.style}
			aria-hidden="true"
		>
			{@render children?.(row.index, row.focus)}
		</div>
	{/each}
</div>
