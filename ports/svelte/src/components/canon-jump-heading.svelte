<script lang="ts" module>
	function scroller(element: HTMLElement): HTMLElement {
		for (
			let at = element.parentElement;
			at;
			at = at.parentElement
		) {
			const style = getComputedStyle(at);
			// a display: contents pane has no box of its own
			if (
				style.display !== 'contents' &&
				/auto|scroll/.test(style.overflowY)
			)
				return at;
		}
		return document.documentElement;
	}
</script>

<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import CanonJumpGrid, {
		type CanonJumpSection,
	} from './canon-jump-grid.svelte';
	import { press } from '../lib/press.ts';
	import { litIndex } from '@canon/lib/jump.ts';
	import { reducedMotion } from '@canon/lib/motion.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-heading.css';
	import '@canon/components/canon-jump-heading.css';

	interface Props extends HTMLAttributes<HTMLHeadingElement> {
		text: string;
		/** Under the group's title in the jump grid: its item count. */
		detail?: string;
	}

	let { text, detail, class: className, ...rest }: Props = $props();

	let sections = $state.raw<CanonJumpSection[]>();
	let current = $state(0);
	let headings: HTMLElement[] = [];

	function show(event: MouseEvent) {
		const heading = (
			event.currentTarget as HTMLElement
		).closest<HTMLElement>('.canon-jump-heading')!;
		const box = scroller(heading);
		const top =
			box === document.documentElement
				? 0
				: box.getBoundingClientRect().top;
		headings = [
			...box.querySelectorAll<HTMLElement>(
				'.canon-jump-heading',
			),
		];
		current = litIndex(
			headings.map((h) => h.getBoundingClientRect().top),
			top,
		);
		sections = headings.map((h) => ({
			title: h.dataset['canonJumpTitle'] ?? '',
			detail: h.dataset['canonJumpDetail'],
		}));
	}

	function pick(index: number) {
		const target = headings[index];
		if (!target?.isConnected) return;
		target.scrollIntoView({
			block: 'start',
			behavior: reducedMotion() ? 'instant' : 'smooth',
		});
		target.querySelector('button')?.focus({ preventScroll: true });
	}
</script>

<!--
  @component
  A CanonHeading with a chevron that opens a CanonJumpGrid of every jump
  heading in the same scrolling box, lit at the group in view; a pick
  scrolls that heading to the top and focuses it.
-->
<h3
	class={['canon-heading canon-jump-heading', className]}
	data-canon-jump-title={text}
	data-canon-jump-detail={detail}
	{...rest}
>
	<button
		type="button"
		class="canon-jump-heading-button"
		aria-haspopup="dialog"
		aria-expanded={sections ? 'true' : 'false'}
		{@attach press}
		onclick={show}
		>{text}<span
			class="canon-jump-heading-chevron"
			aria-hidden="true">›</span
		></button
	>
</h3>
{#if sections}
	<CanonJumpGrid
		open
		{sections}
		{current}
		onPick={pick}
		onClose={() => (sections = undefined)}
	/>
{/if}
