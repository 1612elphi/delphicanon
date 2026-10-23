<script lang="ts">
	import { onDestroy } from 'svelte';
	import type { Attachment } from 'svelte/attachments';
	import type { HTMLAttributes } from 'svelte/elements';
	import { backspace } from '../lib/control-icons.ts';
	import CanonIcon from './canon-icon.svelte';
	import CanonMathKey from './canon-math-key.svelte';
	import CanonMathTabs from './canon-math-tabs.svelte';
	import { opensSlot, type Key } from '@canon/lib/math/expression.ts';
	import {
		glideSpring,
		keyHeights,
		label,
		labelShare,
		menuScale,
		nameScale,
		pages as pageSpecs,
		returnDelay,
		spoken,
		tabHeights,
		type Family,
		type Spec,
	} from '@canon/lib/math/keypad.ts';
	import { canvasMetrics } from '@canon/lib/math/measure.ts';
	import { springEasing } from '@canon/lib/motion.ts';
	import { Typesetter, type Box } from '@canon/lib/math/typeset.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-math-keypad.css';

	interface Props extends HTMLAttributes<HTMLDivElement> {
		/** The first letter key, and the variable of d/dx, ∫ and lim; default x. */
		variable?: string;
		/** The short keys, for a short window. */
		short?: boolean;
		onKey?: (key: Key) => void;
		onDone?: () => void;
	}

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

	let {
		variable = 'x',
		short,
		onKey,
		onDone,
		class: className,
		...rest
	}: Props = $props();

	let progress = $state(0);
	let pageWidth = $state(0);
	let menu = $state.raw<Menu>();
	let pagerElement: HTMLElement | undefined;
	let glide: number | undefined;
	let tracking = false;

	const keyHeight = $derived(
		short ? keyHeights.short : keyHeights.regular,
	);
	const labelSize = $derived(Math.round(keyHeight * labelShare));
	const page = $derived(Math.min(Math.max(Math.round(progress), 0), 3));

	// faces are set once per variable and key size
	const built = $derived<PlacedKey[][]>(
		pageSpecs(variable).map((specs, index) =>
			specs.map((spec) => ({
				spec,
				face: spec.menu
					? new Typesetter(
							canvasMetrics,
							labelSize * menuScale,
						).text(spec.menu.title)
					: label(
							spec.key,
							variable,
							labelSize * spec.scale,
							canvasMetrics,
						),
				label:
					spec.menu?.title ??
					spoken(spec.key, variable),
				id: `${index}-${spec.x}-${spec.y}`,
				style: `grid-column: ${spec.x + 1} / span ${spec.w}; grid-row: ${spec.y + 1} / span ${spec.h}; --canon-math-x: ${spec.x}; --canon-math-w: ${spec.w}`,
			})),
		),
	);

	const pages = $derived(
		built.map((keys, index) => {
			const offset = index - progress;
			return {
				keys,
				index,
				away: index !== page,
				style: `--canon-math-offset-px: ${offset * pageWidth}px; --canon-math-lead: ${offset > 0 ? 1 : 0}; --canon-math-fade: ${1 - 0.7 * Math.min(1, Math.abs(offset))}`,
			};
		}),
	);

	const clearFace = $derived(
		label(
			{ kind: 'clear' },
			variable,
			labelSize * 0.9,
			canvasMetrics,
		),
	);

	const menuStyle = $derived.by(() => {
		if (!menu) return undefined;
		const per = 3;
		const count = Math.ceil(menu.keys.length / per);
		return `--canon-math-menu-cell: ${menu.cell.width}px; --canon-math-key-height: ${menu.cell.height}px; grid-template-rows: repeat(${count}, ${menu.cell.height}px)`;
	});

	function type(key: Key, from: number) {
		closeMenu();
		onKey?.(key);
		if (from === 0 || !opensSlot(key)) return;
		window.setTimeout(() => {
			if (page !== from || glide !== undefined || tracking)
				return;
			show(0);
		}, returnDelay * 1000);
	}

	// MARK: paging

	function show(index: number) {
		closeMenu();
		const pager = pagerElement;
		if (!pager) return;
		const width = pager.clientWidth;
		const target = Math.min(Math.max(index, 0), 3) * width;
		stopGlide();
		if (
			width === 0 ||
			matchMedia('(prefers-reduced-motion: reduce)').matches
		) {
			pager.scrollLeft = target;
			return;
		}
		const from = pager.scrollLeft;
		const start = performance.now();
		const omega = (2 * Math.PI) / glideSpring.response;
		const zeta = glideSpring.damping;
		const damped = omega * Math.sqrt(1 - zeta * zeta);
		pager.classList.add('canon-math-keypad-pager--gliding');
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
			if (
				t > 1.2 ||
				(t > 0.2 && Math.abs(x - target) < 0.3)
			) {
				pager.scrollLeft = target;
				stopGlide();
				return;
			}
			pager.scrollLeft = x;
			glide = requestAnimationFrame(frame);
		};
		glide = requestAnimationFrame(frame);
	}

	function stopGlide() {
		if (glide !== undefined) cancelAnimationFrame(glide);
		glide = undefined;
		pagerElement?.classList.remove(
			'canon-math-keypad-pager--gliding',
		);
	}

	const pager: Attachment<HTMLElement> = (element) => {
		pagerElement = element;
		const scrolled = () => {
			const width = element.clientWidth;
			if (width === 0) return;
			pageWidth = width;
			progress = element.scrollLeft / width;
		};
		const down = () => {
			tracking = true;
			stopGlide();
		};
		const up = () => (tracking = false);
		const resize = new ResizeObserver(() => {
			if (glide === undefined)
				element.scrollLeft = page * element.clientWidth;
			scrolled();
		});
		resize.observe(element);
		element.addEventListener('scroll', scrolled, { passive: true });
		element.addEventListener('pointerdown', down);
		element.addEventListener('wheel', down, { passive: true });
		element.addEventListener('pointerup', up);
		element.addEventListener('pointercancel', up);
		element.addEventListener('scrollend', up);
		return () => {
			stopGlide();
			resize.disconnect();
			element.removeEventListener('scroll', scrolled);
			element.removeEventListener('pointerdown', down);
			element.removeEventListener('wheel', down);
			element.removeEventListener('pointerup', up);
			element.removeEventListener('pointercancel', up);
			element.removeEventListener('scrollend', up);
		};
	};

	// MARK: submenu

	function openMenu(placed: PlacedKey, from: number) {
		const spec = placed.spec.menu;
		const anchor = pagerElement?.querySelector<HTMLElement>(
			`[data-canon-math-key="${placed.id}"]`,
		);
		if (!spec || !anchor) return;
		const size = labelSize;
		menu = {
			keys: spec.keys.map((key) => ({
				key,
				face: label(
					key,
					variable,
					size * nameScale,
					canvasMetrics,
				),
				label: spoken(key, variable),
			})),
			family: placed.spec.family,
			page: from,
			anchor,
			cell: {
				width: Math.max(
					64,
					anchor.offsetWidth / 3 + 12,
				),
				height: keyHeight,
			},
		};
	}

	function closeMenu() {
		menu = undefined;
	}

	/** Opens over its key, growing out of the key's top edge; a touch elsewhere or Escape closes it. */
	const placeMenu =
		(menu: Menu): Attachment<HTMLElement> =>
		(panel) => {
			const root = panel.parentElement!;
			const box = root.getBoundingClientRect();
			const anchor = menu.anchor.getBoundingClientRect();
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
			if (
				!matchMedia('(prefers-reduced-motion: reduce)')
					.matches
			) {
				const dx = (midX - (left + width / 2)) * 0.6;
				const dy =
					(anchor.top -
						box.top -
						(top + height / 2)) *
					0.6;
				panel.animate(
					[
						{
							transform: `translate(${dx}px, ${dy}px) scale(0.4)`,
							opacity: 0,
						},
						{
							transform: 'none',
							opacity: 1,
						},
					],
					{
						duration: 340,
						easing: springEasing(0.74),
					},
				);
			}
			panel.querySelector<HTMLElement>('button')?.focus({
				preventScroll: true,
			});
			const outside = (event: PointerEvent) => {
				if (!panel.contains(event.target as Node))
					closeMenu();
			};
			const escape = (event: KeyboardEvent) => {
				if (event.key !== 'Escape') return;
				event.preventDefault();
				event.stopPropagation();
				closeMenu();
				menu.anchor.focus({ preventScroll: true });
			};
			document.addEventListener('pointerdown', outside, true);
			document.addEventListener('keydown', escape, true);
			return () => {
				document.removeEventListener(
					'pointerdown',
					outside,
					true,
				);
				document.removeEventListener(
					'keydown',
					escape,
					true,
				);
			};
		};

	onDestroy(stopGlide);
</script>

<!--
  @component
  Maths keys on four swipeable pages (numbers and operators, functions,
  calculus, letters and constants), with delete, clear and Done beside every
  page. Hyperbolic and reciprocal trig sit in submenus. A slot key typed on a
  later page returns to the numbers, since the slot usually takes a number
  next.
-->
<div
	class={['canon-math-keypad', className]}
	style="--canon-math-key-height: {keyHeight}px; --canon-math-tab-height: {short
		? tabHeights.short
		: tabHeights.regular}px"
	{...rest}
>
	<CanonMathTabs {progress} onSelect={show} />
	<div class="canon-math-keypad-pager" {@attach pager}>
		{#each pages as sheet (sheet.index)}
			<div
				class="canon-math-keypad-page"
				style={sheet.style}
				inert={sheet.away}
			>
				{#each sheet.keys as placed (placed.id)}
					{#if placed.spec.menu}
						<CanonMathKey
							face={placed.face}
							family={placed.spec
								.family}
							label={placed.label}
							menu
							onClick={() =>
								openMenu(
									placed,
									sheet.index,
								)}
							style={placed.style}
							data-canon-math-key={placed.id}
						/>
					{:else}
						<CanonMathKey
							face={placed.face}
							family={placed.spec
								.family}
							label={placed.label}
							onClick={() =>
								type(
									placed
										.spec
										.key,
									sheet.index,
								)}
							style={placed.style}
							data-canon-math-key={placed.id}
						/>
					{/if}
				{/each}
			</div>
		{/each}
	</div>
	<div class="canon-math-keypad-spine">
		<CanonMathKey
			family="operation"
			label="Delete"
			repeats
			onClick={() => onKey?.({ kind: 'delete' })}
			><CanonIcon svg={backspace} /></CanonMathKey
		>
		<CanonMathKey
			face={clearFace}
			family="clear"
			label="Clear"
			onClick={() => onKey?.({ kind: 'clear' })}
		/>
		<CanonMathKey
			class="canon-math-keypad-done"
			family="done"
			label="Done"
			onClick={() => onDone?.()}>Done</CanonMathKey
		>
	</div>
	{#if menu}
		<div
			class="canon-math-submenu canon-math-key--{menu.family}"
			role="menu"
			style={menuStyle}
			{@attach placeMenu(menu)}
		>
			{#each menu.keys as item, i (i)}
				<CanonMathKey
					face={item.face}
					family={menu.family}
					label={item.label}
					onClick={() =>
						type(item.key, menu!.page)}
					role="menuitem"
				/>
			{/each}
		</div>
	{/if}
</div>
