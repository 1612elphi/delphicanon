import type { HTMLAttributes } from 'react';
import {
	contrastFigure,
	contrastLevels,
	contrastRatio,
	formatColour,
	formatLabel,
	hex as hexOf,
	type ColourFormat,
	type Rgb,
} from '@canon/lib/colour.ts';
import { cx } from '../lib/class-names.ts';
import CanonValueLine from './canon-value-line.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-colour-card.css';

export interface CanonColourCardProps extends HTMLAttributes<HTMLDivElement> {
	colour: Rgb;
	/**
	 * chip: swatch above, name and three values below. row: swatch at the
	 * leading edge, name and one value beside it, for lists.
	 */
	layout?: 'chip' | 'row';
	/** Shown instead of the nearest named colour. */
	name?: string;
	/** Nearest colour name for a hex. */
	nameOf?: (hex: string) => string;
	/** The app's colour format settings; default hex and rgb. */
	primaryFormat?: ColourFormat;
	secondaryFormat?: ColourFormat;
}

/**
 * A paint chip: the colour over its name and values. The swatch carries
 * white and black type with their contrast ratios; each value line copies
 * itself on a tap.
 */
export default function CanonColourCard({
	colour,
	layout = 'chip',
	name,
	nameOf,
	primaryFormat,
	secondaryFormat,
	className,
	...rest
}: CanonColourCardProps) {
	const hex = hexOf(colour);
	const shown: ColourFormat[] = ['hex'];
	for (const format of [
		primaryFormat ?? 'hex',
		secondaryFormat ?? 'rgb',
		'oklch',
		'rgb',
	] as const) {
		if (!shown.includes(format)) shown.push(format);
	}
	const lines = shown.slice(0, layout === 'chip' ? 3 : 1);
	const inks = [1, 0].map((level) => {
		const ratio = contrastRatio(colour, [level, level, level]);
		return {
			level,
			figure: contrastFigure(ratio),
			faint: ratio < contrastLevels.aa,
		};
	});

	return (
		<div
			className={cx(
				'canon-colour-card',
				`canon-colour-card--${layout}`,
				className,
			)}
			{...rest}
		>
			<div
				className="canon-colour-card-swatch"
				style={{ background: hex }}
			>
				{layout === 'chip' &&
					inks.map((ink) => (
						<span
							key={ink.level}
							className="canon-colour-card-ink"
							style={{
								color: ink.level
									? 'white'
									: 'black',
								opacity: ink.faint
									? 0.45
									: 1,
							}}
							aria-hidden="true"
						>
							<span className="canon-colour-card-specimen">
								Aa
							</span>
							<span className="canon-colour-card-ratio">
								{ink.figure}
							</span>
						</span>
					))}
			</div>
			<div className="canon-colour-card-info">
				<div className="canon-colour-card-name">
					{name ?? nameOf?.(hex) ?? hex}
				</div>
				{lines.map((format) => (
					<CanonValueLine
						key={format}
						label={formatLabel(format)}
						value={formatColour(
							colour,
							format,
						)}
					/>
				))}
			</div>
		</div>
	);
}
