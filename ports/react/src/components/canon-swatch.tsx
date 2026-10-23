import type { ButtonHTMLAttributes, Ref } from 'react';
import { hex as hexOf, takesBlackInk, type Rgb } from '@canon/lib/colour.ts';
import { cx } from '../lib/class-names.ts';
import { press } from '../lib/press.ts';
import { useRefs } from '../lib/refs.ts';
import { canonToast } from '../lib/toast-store.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-swatch.css';

export interface CanonSwatchProps extends ButtonHTMLAttributes<HTMLButtonElement> {
	colour: Rgb;
	/** Nearest colour name for a hex, read by assistive technology. */
	nameOf?: (hex: string) => string;
	ref?: Ref<HTMLButtonElement>;
}

/**
 * One colour, its hex where it fits; a tap copies the hex. The swatch of a
 * CanonColourStrip palette. Its width comes from the parent (a grid cell or
 * a flex item that grows): it measures itself for the hex.
 */
export default function CanonSwatch({
	colour,
	nameOf,
	className,
	style,
	ref,
	...rest
}: CanonSwatchProps) {
	const hex = hexOf(colour);
	const name = nameOf?.(hex);
	return (
		<button
			type="button"
			className={cx('canon-swatch', className)}
			style={{
				background: hex,
				color: takesBlackInk(colour)
					? 'black'
					: 'white',
				...style,
			}}
			aria-label={name ? `${name} ${hex}` : hex}
			onClick={() => void canonToast.copy(hex)}
			ref={useRefs(press, ref)}
			{...rest}
		>
			<span className="canon-swatch-hex" aria-hidden="true">
				{hex}
			</span>
		</button>
	);
}
