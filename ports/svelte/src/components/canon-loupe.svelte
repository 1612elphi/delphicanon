<script lang="ts" module>
	export type CanonLoupePixels =
		ImageData | ImageBitmap | HTMLCanvasElement | HTMLImageElement;

	/** 31 px across when no pixels are given, as on iOS. */
	const defaultCount = 31;
</script>

<script lang="ts">
	import type { Attachment } from 'svelte/attachments';
	import type { HTMLAttributes } from 'svelte/elements';
	import { hex, takesBlackInk, type Rgb } from '@canon/lib/colour.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-loupe.css';

	interface Props extends HTMLAttributes<HTMLDivElement> {
		/** The pixels around the sample point, one canvas pixel each, the sample in the middle. */
		pixels?: CanonLoupePixels;
		/** The sampled colour: the frame, and the ground behind missing pixels. */
		colour: Rgb;
	}

	let { pixels, colour, class: className, ...rest }: Props = $props();

	const count = $derived(pixels?.width || defaultCount);
	const style = $derived.by(() => {
		const ink = takesBlackInk(colour)
			? 'var(--canon-loupe-ink-dark)'
			: 'var(--canon-loupe-ink-light)';
		return `--canon-loupe-colour: ${hex(colour)}; --canon-loupe-ink: ${ink}; --canon-loupe-count: ${count}`;
	});

	function draw(
		pixels: CanonLoupePixels | undefined,
	): Attachment<HTMLCanvasElement> {
		return (canvas) => {
			const context = canvas.getContext('2d');
			if (!context) return;
			if (!pixels) {
				context.clearRect(
					0,
					0,
					canvas.width,
					canvas.height,
				);
				return;
			}
			canvas.width = pixels.width;
			canvas.height = pixels.height;
			if (pixels instanceof ImageData)
				context.putImageData(pixels, 0, 0);
			else context.drawImage(pixels, 0, 0);
		};
	}
</script>

<!--
  @component
  The pixels around a sample point, magnified without smoothing, framed in
  the sampled colour. Place it with `frame` from `lib/loupe.ts`; it takes
  no pointer input.
-->
<div class={['canon-loupe', className]} {style} aria-hidden="true" {...rest}>
	<canvas class="canon-loupe-pixels" {@attach draw(pixels)}></canvas>
	<div class="canon-loupe-centre"></div>
</div>
