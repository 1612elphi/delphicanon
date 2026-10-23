<script lang="ts" module>
	import type { Overlays } from '@canon/lib/colour-solid/solid.ts';
	import { takesBlackInk, type Rgb } from '@canon/lib/colour.ts';
	import { capture } from '@canon/lib/motion.ts';

	/** Travel in px before a press becomes a drag, as UIPanGestureRecognizer's slop. */
	const dragSlop = 10;
	/** Pointer history in ms used for the fling speed. */
	const flingWindow = 100;

	const reducedMotion = () =>
		window.matchMedia('(prefers-reduced-motion: reduce)').matches;

	const sameValues = (a?: readonly number[], b?: readonly number[]) =>
		a === b ||
		(!!a &&
			!!b &&
			a.length === b.length &&
			a.every((v, i) => v === b[i]));

	const css = (c: Rgb) =>
		`color(srgb ${c.map((v) => v.toFixed(4)).join(' ')})`;

	/** Moves the markers, letters and wireframe to where the state puts them. */
	function place(root: HTMLElement, overlays: Overlays, whole: boolean) {
		const layer = root.querySelector<HTMLElement>(
			'.canon-colour-solid-overlay',
		)!;
		const pick = layer.querySelector<HTMLElement>(
			'.canon-colour-solid-marker--pick',
		)!;
		mark(pick, overlays.pick.at, overlays.pick.colour);

		const marks = [
			...layer.querySelectorAll<HTMLElement>(
				'.canon-colour-solid-marker--mark',
			),
		];
		while (marks.length < overlays.marks.length) {
			const view = document.createElement('span');
			view.className =
				'canon-colour-solid-marker canon-colour-solid-marker--mark';
			layer.insertBefore(view, pick);
			marks.push(view);
		}
		marks.forEach((view, i) => {
			const m = overlays.marks[i];
			if (m) mark(view, m.at, m.colour);
			else view.hidden = true;
		});

		const labels = [
			...layer.querySelectorAll<HTMLElement>(
				'.canon-colour-solid-axis',
			),
		];
		while (labels.length < overlays.labels.length) {
			const label = document.createElement('span');
			label.className = 'canon-colour-solid-axis';
			layer.prepend(label);
			labels.push(label);
		}
		labels.forEach((label, i) => {
			const l = overlays.labels[i];
			label.hidden = !l?.at || overlays.labelsHidden;
			if (!l?.at) return;
			label.textContent = l.letter;
			label.style.translate = `${l.at.x}px ${l.at.y}px`;
			// k fades with wireframe
			label.classList.toggle(
				'canon-colour-solid-axis--depth',
				i === 3,
			);
		});

		root.classList.toggle('canon-colour-solid--whole', whole);
		const path = root.querySelector(
			'.canon-colour-solid-wire path',
		)!;
		path.setAttribute('d', overlays.tesseract ?? '');
	}

	function mark(
		view: HTMLElement,
		at: { x: number; y: number; hidden: boolean } | undefined,
		colour: Rgb,
	) {
		view.hidden = !at;
		if (!at) return;
		view.style.translate = `${at.x}px ${at.y}px`;
		view.style.backgroundColor = at.hidden ? '' : css(colour);
		view.dataset['ink'] = takesBlackInk(colour) ? 'black' : 'white';
		view.toggleAttribute('data-hollow', at.hidden);
	}
</script>

<script lang="ts">
	import { untrack } from 'svelte';
	import type { Attachment } from 'svelte/attachments';
	import type { HTMLAttributes } from 'svelte/elements';
	import {
		createRenderer,
		type Renderer,
	} from '@canon/lib/colour-solid/shader.ts';
	import {
		SolidState,
		solidMotion,
	} from '@canon/lib/colour-solid/solid.ts';
	import { hex } from '@canon/lib/colour.ts';
	import {
		colourAt,
		pointFor,
		spaceNames,
		type SolidSpace as Space,
	} from '@canon/lib/colour-space.ts';
	import {
		identity,
		type Mat3,
		type Vec4,
	} from '@canon/lib/colour-solid/vec.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-colour-solid.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'onchange'
	> {
		/** Default `hsl`. */
		space?: Space;
		/**
		 * The picked colour's channels, each 0...1 (chroma may pass 1), in
		 * `space`'s units. Order: rgb r g b; hsl h l s; lab and oklab a L b;
		 * cmyk c m y k; the rest hue, radius, height. Only cmyk uses the fourth.
		 * A new `space` with an unchanged `point` converts the pick and reports
		 * it through `onChange`. Default: a dark green.
		 */
		point?: readonly number[];
		/** A change of `point` eases the drawing to it (`setPoint(_:animated:)`), as for a tap on a slider track. */
		animated?: boolean;
		/**
		 * Index into `point` of the channel to slice along, 0...2. The solid
		 * draws faint, the slice through the pick opaque, and a tap or a drag
		 * picks on the slice; nothing is cut away. CMYK's black has no slice:
		 * see `showsWhole`.
		 */
		sliceAxis?: number | null;
		/**
		 * Turns the slice to face the viewer and flattens the view, so a drag on
		 * the slice moves the pick as on a 2D picker. A chroma or saturation
		 * shell unrolls into a flat sheet.
		 */
		isOrtho?: boolean;
		/** Fades the solid around a slice to opaque, while black changes. */
		showsWhole?: boolean;
		/** Without a slice, cuts away the part between the pick and the viewer. Default true. */
		cutsAway?: boolean;
		/** Further colours, drawn as small squares, hollow where the solid hides them. */
		marks?: readonly Rgb[];
		/**
		 * Rows of a 3x3 matrix on sRGB that every drawn colour goes through
		 * (`setVision(_:animated:)`); changes ease. Default identity.
		 */
		vision?: readonly (readonly number[])[];
		/** After every pick, with the new point and its colour. */
		onChange?: (point: Vec4, colour: Rgb) => void;
		/** Nearest colour name, read out before the hex value. */
		closestName?: (colour: Rgb) => string;
	}

	let {
		space,
		point,
		animated,
		sliceAxis,
		isOrtho,
		showsWhole,
		cutsAway,
		marks,
		vision,
		onChange,
		closestName,
		class: className,
		onkeydown,
		...rest
	}: Props = $props();

	const state = untrack(
		() =>
			new SolidState(
				space ?? 'hsl',
				(point as Vec4 | undefined) ??
					pointFor(
						space ?? 'hsl',
						[0.12, 0.4, 0.15],
					),
				() => redraw(),
			),
	);

	let synced:
		| {
				space?: Space;
				point?: readonly number[];
				marks?: readonly Rgb[];
		  }
		| undefined;
	let root: HTMLDivElement | undefined;
	let renderer: Renderer | undefined;
	let frame = 0;
	let last: number | undefined;
	let valueText = '';

	const label = $derived(spaceNames[space ?? 'hsl']);

	function redraw() {
		if (root && !frame) frame = requestAnimationFrame(draw);
	}

	function draw(now: number) {
		frame = 0;
		const dt =
			last === undefined ? 0 : Math.max(0, now - last) / 1000;
		state.tick(dt);
		last = state.animating ? now : undefined;
		paint();
	}

	/** Draws the solid and places the overlays now. */
	function paint() {
		if (!root) return;
		const width = root.clientWidth;
		const height = root.clientHeight;
		state.size = { width, height };
		const canvas = root.querySelector('canvas')!;
		const ratio = window.devicePixelRatio || 1;
		const pixels = [
			Math.round(width * ratio),
			Math.round(height * ratio),
		] as const;
		if (canvas.width !== pixels[0] || canvas.height !== pixels[1]) {
			[canvas.width, canvas.height] = pixels;
		}
		if (width > 0 && height > 0) {
			renderer?.draw(state.uniforms(...pixels), ...pixels);
		}
		place(root, state.overlays(), state.showsWhole);
		const colour = colourAt(state.space, state.point);
		const name = closestName?.(colour);
		const text = name ? `${name}, ${hex(colour)}` : hex(colour);
		if (text !== valueText) {
			valueText = text;
			root.querySelector('output')!.textContent = text;
		}
	}

	function notify() {
		onChange?.(
			[...state.point],
			colourAt(state.space, state.point),
		);
	}

	const setup: Attachment<HTMLDivElement> = (element) =>
		untrack(() => {
			root = element;
			renderer = createRenderer(
				element.querySelector('canvas')!,
			);
			element.dataset['gl'] = renderer ? 'ready' : 'none';

			const resize = new ResizeObserver(() => redraw());
			resize.observe(element);
			const motion = window.matchMedia(
				'(prefers-reduced-motion: reduce)',
			);
			const motionChanged = () =>
				(state.animates = !motion.matches);
			motion.addEventListener('change', motionChanged);

			const local = (e: PointerEvent) => {
				const box = element.getBoundingClientRect();
				return {
					x:
						((e.clientX - box.left) *
							element.clientWidth) /
						(box.width || 1),
					y:
						((e.clientY - box.top) *
							element.clientHeight) /
						(box.height || 1),
				};
			};
			let drag:
				| {
						id: number;
						start: { x: number; y: number };
						last: { x: number; y: number };
						grabbed: boolean;
						active: boolean;
						picks: boolean;
						samples: {
							t: number;
							x: number;
							y: number;
						}[];
				  }
				| undefined;

			const down = (e: PointerEvent) => {
				if (e.button !== 0 || drag) return;
				const at = local(e);
				const grabbed = state.grabs(at);
				drag = {
					id: e.pointerId,
					start: at,
					last: at,
					grabbed,
					active: false,
					picks: false,
					samples: [{ t: e.timeStamp, ...at }],
				};
				if (grabbed) capture(element, e.pointerId);
			};
			const move = (e: PointerEvent) => {
				if (!drag || e.pointerId !== drag.id) return;
				const at = local(e);
				drag.samples.push({ t: e.timeStamp, ...at });
				drag.samples = drag.samples.filter(
					(s) => e.timeStamp - s.t <= flingWindow,
				);
				if (!drag.active) {
					const travel = Math.hypot(
						at.x - drag.start.x,
						at.y - drag.start.y,
					);
					if (!drag.grabbed || travel < dragSlop)
						return;
					drag.active = true;
					state.stopSpin();
					drag.picks =
						state.nearPick(at) ||
						!state.dragsTurn;
				}
				if (drag.picks) {
					// misses keep last pick
					if (state.pick(at)) notify();
				} else {
					state.turn(
						(at.x - drag.last.x) *
							solidMotion.turnRate,
						(at.y - drag.last.y) *
							solidMotion.turnRate,
					);
				}
				drag.last = at;
			};
			const up = (e: PointerEvent) => {
				if (!drag || e.pointerId !== drag.id) return;
				const at = local(e);
				if (drag.active && !drag.picks) {
					const first = drag.samples.find(
						(s) =>
							e.timeStamp - s.t <=
							flingWindow,
					);
					const seconds = first
						? (e.timeStamp - first.t) / 1000
						: 0;
					if (first && seconds > 0) {
						state.startSpin(
							((at.x - first.x) /
								seconds) *
								solidMotion.turnRate,
							((at.y - first.y) /
								seconds) *
								solidMotion.turnRate,
						);
					}
				} else if (
					!drag.active &&
					Math.hypot(
						at.x - drag.start.x,
						at.y - drag.start.y,
					) < dragSlop &&
					state.pick(at)
				) {
					notify();
				}
				drag = undefined;
			};
			const cancel = () => (drag = undefined);

			element.addEventListener('pointerdown', down);
			element.addEventListener('pointermove', move);
			element.addEventListener('pointerup', up);
			element.addEventListener('pointercancel', cancel);
			paint();

			return () => {
				cancelAnimationFrame(frame);
				frame = 0;
				root = undefined;
				resize.disconnect();
				motion.removeEventListener(
					'change',
					motionChanged,
				);
				element.removeEventListener(
					'pointerdown',
					down,
				);
				element.removeEventListener(
					'pointermove',
					move,
				);
				element.removeEventListener('pointerup', up);
				element.removeEventListener(
					'pointercancel',
					cancel,
				);
				renderer?.destroy();
				renderer = undefined;
			};
		});

	// re-runs when any prop it reads changes, as the Ember update modifier
	const update: Attachment<HTMLDivElement> = () => {
		const named = {
			space: space ?? 'hsl',
			point,
			animated,
			sliceAxis,
			isOrtho,
			showsWhole,
			cutsAway,
			marks,
			vision,
		};
		untrack(() => {
			// first arguments: no motion
			state.animates =
				synced !== undefined && !reducedMotion();
			const pointChanged = !sameValues(
				named.point,
				synced?.point,
			);
			if (named.space !== state.space) {
				state.setSpace(named.space);
				if (!pointChanged) queueMicrotask(notify);
			}
			if (
				named.point &&
				pointChanged &&
				!sameValues(named.point, state.point)
			) {
				state.setPoint(
					[...named.point] as Vec4,
					named.animated ?? false,
				);
			}
			state.setVision(
				(named.vision as Mat3 | undefined) ?? identity,
				true,
			);
			if (named.marks !== synced?.marks)
				state.setMarks([...(named.marks ?? [])]);
			state.setCutsAway(named.cutsAway ?? true);
			// controls order: ortho, then slice
			state.setOrtho(named.isOrtho ?? false);
			state.setSliceAxis(named.sliceAxis ?? null);
			state.setShowsWhole(named.showsWhole ?? false);
			state.animates = !reducedMotion();
			synced = {
				space: named.space,
				point: named.point,
				marks: named.marks,
			};
		});
	};

	function key(e: KeyboardEvent & { currentTarget: HTMLDivElement }) {
		onkeydown?.(e);
		const turns: Record<string, [number, number]> = {
			ArrowLeft: [-solidMotion.keyTurn, 0],
			ArrowRight: [solidMotion.keyTurn, 0],
			ArrowUp: [0, -solidMotion.keyTurn],
			ArrowDown: [0, solidMotion.keyTurn],
		};
		const turn = turns[e.key];
		if (!turn || !state.dragsTurn) return;
		e.preventDefault();
		state.stopSpin();
		state.turn(...turn);
	}
</script>

<!--
  @component
  A colour space drawn as a solid: drag to turn it, tap a face to pick the
  colour there, drag from the pick to move it over the faces. The part of
  the solid between the pick and the viewer is cut away. CMYK has four
  channels: black is depth, and the CMY cube shrinks inside a wireframe of
  black's range.
-->
<!-- svelte-ignore a11y_no_noninteractive_tabindex -->
<div
	class={['canon-colour-solid', className]}
	tabindex="0"
	role="group"
	aria-label={label}
	onkeydown={key}
	{@attach setup}
	{@attach update}
	{...rest}
>
	<canvas class="canon-colour-solid-canvas"></canvas>
	<svg class="canon-colour-solid-wire" aria-hidden="true"><path /></svg>
	<div class="canon-colour-solid-overlay" aria-hidden="true">
		<span
			class="canon-colour-solid-marker canon-colour-solid-marker--pick"
		></span>
	</div>
	<output class="canon-colour-solid-value" aria-live="polite"></output>
</div>
