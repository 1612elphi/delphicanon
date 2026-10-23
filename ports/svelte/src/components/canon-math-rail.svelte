<script lang="ts" module>
	export const railHeights = { regular: 44, short: 38 };
	/** Sideways drag, in px, per caret place. */
	export const stride = 16;
	export const arrowWidth = 50;
</script>

<script lang="ts">
	import type { Attachment } from 'svelte/attachments';
	import type { HTMLAttributes } from 'svelte/elements';
	import CanonButton from './canon-button.svelte';
	import { iconSnippet } from '../lib/control-icons.ts';
	import { capture } from '@canon/lib/motion.ts';
	import type { Key } from '@canon/lib/math/expression.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-math-rail.css';

	interface Props extends HTMLAttributes<HTMLDivElement> {
		/** Moves the caret; false when it could not move. */
		onStep?: (key: Key) => boolean;
		short?: boolean;
	}

	let { onStep, short, class: className, ...rest }: Props = $props();

	const chevron = (d: string) =>
		iconSnippet(
			`<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="${d}"/></svg>`,
		);

	const arrows = [
		{
			key: { kind: 'left' },
			label: 'Left',
			icon: chevron('m15 18-6-6 6-6'),
		},
		{
			key: { kind: 'up' },
			label: 'Up',
			icon: chevron('m18 15-6-6-6 6'),
		},
		{
			key: { kind: 'down' },
			label: 'Down',
			icon: chevron('m6 9 6 6 6-6'),
		},
		{
			key: { kind: 'right' },
			label: 'Right',
			icon: chevron('m9 18 6-6-6-6'),
		},
	] as const;

	let phase = $state(0);

	const step = (key: Key) => onStep?.(key) ?? false;

	const drag: Attachment<HTMLElement> = (ribs) => {
		let last = 0;
		let stepped = 0;
		let start: number | undefined;
		const down = (event: PointerEvent) => {
			if (event.button !== 0) return;
			event.stopPropagation();
			capture(ribs, event.pointerId);
			start = event.clientX;
			last = 0;
			stepped = 0;
		};
		const move = (event: PointerEvent) => {
			if (start === undefined) return;
			const x = event.clientX - start;
			phase += x - last;
			last = x;
			while (x - stepped > stride) {
				stepped += stride;
				step({ kind: 'right' });
			}
			while (x - stepped < -stride) {
				stepped -= stride;
				step({ kind: 'left' });
			}
		};
		const up = () => (start = undefined);
		ribs.addEventListener('pointerdown', down);
		ribs.addEventListener('pointermove', move);
		ribs.addEventListener('pointerup', up);
		ribs.addEventListener('pointercancel', up);
		return () => {
			ribs.removeEventListener('pointerdown', down);
			ribs.removeEventListener('pointermove', move);
			ribs.removeEventListener('pointerup', up);
			ribs.removeEventListener('pointercancel', up);
		};
	};
</script>

<!--
  @component
  The caret's controls, under the expression: ribs that slide with a
  sideways drag, one caret place per stride, then the four arrow keys.
-->
<div
	class={['canon-math-rail', className]}
	style="--canon-math-rail-height: {short
		? railHeights.short
		: railHeights.regular}px; --canon-math-arrow-width: {arrowWidth}px"
	{...rest}
>
	<div
		class="canon-math-rail-ribs"
		style="--canon-math-rail-phase: {phase}px"
		aria-hidden="true"
		{@attach drag}
	></div>
	{#each arrows as arrow (arrow.label)}
		<CanonButton
			kind="cell"
			icon={arrow.icon}
			label={arrow.label}
			repeats
			onClick={() => step(arrow.key)}
		/>
	{/each}
</div>
