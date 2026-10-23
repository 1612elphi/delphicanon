<script lang="ts" module>
	export const lampHeight = 3;
</script>

<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import { press } from '../lib/press.ts';
	import CanonMathView from './canon-math-view.svelte';
	import { canvasMetrics } from '@canon/lib/math/measure.ts';
	import { Typesetter } from '@canon/lib/math/typeset.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-math-tabs.css';

	interface Props extends HTMLAttributes<HTMLDivElement> {
		/** The page position, fractional mid-swipe. */
		progress: number;
		onSelect?: (page: number) => void;
	}

	let {
		progress: givenProgress,
		onSelect,
		class: className,
		...rest
	}: Props = $props();

	const accents = [
		'var(--canon-foreground)',
		'var(--canon-math-green)',
		'var(--canon-math-blue)',
		'var(--canon-math-clay)',
	];
	const names = ['Numbers', 'Functions', 'Calculus', 'Letters'];

	function faces() {
		const setter = new Typesetter(canvasMetrics, 18);
		const functions = setter
			.text('f', { italic: true })
			.append(
				setter.parens(
					setter.text('x', { italic: true }),
					0,
				),
				1,
			);
		const calculus = setter.text('∫').append(setter.text('Σ'), 3);
		return [
			setter.text('123'),
			functions,
			calculus,
			setter.text('xyz', { italic: true }),
		];
	}

	const shown = faces();

	const progress = $derived(
		Math.min(Math.max(givenProgress, 0), names.length - 1),
	);
	const tabs = $derived(
		shown.map((face, index) => {
			const near = Math.max(
				0,
				1 - Math.abs(progress - index),
			);
			return {
				face,
				index,
				name: names[index]!,
				selected: near > 0.5,
				style: `color: color-mix(in srgb, var(--canon-muted-foreground), ${accents[index]} ${Math.round(near * 100)}%)`,
			};
		}),
	);
	const lampStyle = $derived.by(() => {
		const low = Math.floor(progress);
		const high = Math.min(low + 1, names.length - 1);
		const share = progress - low;
		// lamp narrows mid-swipe
		const width = 0.62 * (1 - 0.35 * Math.sin(Math.PI * share));
		return `--canon-math-progress: ${progress}; --canon-math-lamp: ${width}; background: color-mix(in srgb, ${accents[low]}, ${accents[high]} ${Math.round(share * 100)}%)`;
	});
</script>

<!--
  @component
  The pages' names as maths, each lit in its page's colour as the page comes
  into view, over a lamp that slides and changes colour with the swipe.
-->
<div class={['canon-math-tabs', className]} {...rest}>
	{#each tabs as tab (tab.index)}
		<button
			type="button"
			class="canon-math-tab"
			aria-label={tab.name}
			aria-current={tab.selected ? 'true' : undefined}
			style={tab.style}
			onclick={() => onSelect?.(tab.index)}
			{@attach press}
			><CanonMathView
				box={tab.face}
				mono
				aria-hidden="true"
			/></button
		>
	{/each}
	<span class="canon-math-tabs-lamp" style={lampStyle}></span>
</div>
