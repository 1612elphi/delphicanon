<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { Attachment } from 'svelte/attachments';
	import type { HTMLAttributes } from 'svelte/elements';
	import { balanced, spans } from '@canon/lib/grid.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-grid.css';

	interface Props extends HTMLAttributes<HTMLDivElement> {
		/** Cells per row at most; default all in one row. */
		columns?: number;
		/** Draws the outer hairline; leave off inside CanonRows or a CanonRow. */
		boxed?: boolean;
		children?: Snippet;
	}

	let {
		columns,
		boxed,
		children,
		class: className,
		...rest
	}: Props = $props();

	// iOS: insets 24, symbol padding 6, slack 8
	const titleRoom = 38;
	let measure: CanvasRenderingContext2D | null | undefined;

	function titleFits(button: HTMLElement): boolean {
		const title = button.querySelector<HTMLElement>(
			'.canon-button-title',
		);
		measure ??= document.createElement('canvas').getContext('2d');
		if (!title || !measure) return true;
		measure.font = getComputedStyle(title).font;
		const iconWidth =
			parseFloat(
				getComputedStyle(button).getPropertyValue(
					'--canon-icon-inline',
				),
			) || 0;
		return (
			measure.measureText(title.textContent ?? '').width +
				iconWidth +
				titleRoom <=
			button.clientWidth
		);
	}

	function layout(columns: number | undefined): Attachment<HTMLElement> {
		return (grid) => {
			const place = () => {
				// a popover or menu panel renders beside its trigger and is no cell
				const cells = [...grid.children].filter(
					(child) =>
						!child.hasAttribute('popover'),
				) as HTMLElement[];
				const perRow = spans(
					cells.length,
					columns ?? cells.length,
				);
				const widest =
					balanced(
						cells.length,
						columns ?? cells.length,
					)[0] ?? 1;
				grid.style.setProperty(
					'--canon-grid-columns',
					String(widest),
				);
				cells.forEach((cell, i) => {
					const span = perRow[i] ?? 1;
					cell.style.gridColumn =
						span > 1 ? `span ${span}` : '';
				});
				fit();
			};
			// titles drop together
			const fit = () => {
				const tight = [...grid.children].some(
					(cell) =>
						cell instanceof HTMLElement &&
						cell.matches(
							'[data-canon-fit]',
						) &&
						!titleFits(cell),
				);
				grid.toggleAttribute('data-symbol-only', tight);
			};
			place();
			const children = new MutationObserver(place);
			children.observe(grid, { childList: true });
			const titles = new MutationObserver(fit);
			titles.observe(grid, {
				characterData: true,
				subtree: true,
			});
			const size = new ResizeObserver(fit);
			size.observe(grid);
			void document.fonts?.ready.then(fit);
			return () => {
				children.disconnect();
				titles.disconnect();
				size.disconnect();
			};
		};
	}
</script>

<!--
  @component
  Equal cells divided by hairlines. Rows are balanced, so four cells at
  three columns give two rows of two; the last cell of a short row spans the
  rest. Filling buttons with a symbol all show the symbol alone when any
  one title does not fit.
-->
<div
	class={['canon-grid', boxed && 'canon-grid--boxed', className]}
	{@attach layout(columns)}
	{...rest}
>
	{@render children?.()}
</div>
