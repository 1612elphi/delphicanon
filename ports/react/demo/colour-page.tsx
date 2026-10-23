import { useState } from 'react';
import {
	fromOklch,
	hex,
	luminance,
	oklabToLinear,
	oklch,
	parseHex,
	type Rgb,
} from '@canon/lib/colour.ts';
import { solidSpaces, spaceNames } from '@canon/lib/colour-space.ts';
import { frame } from '@canon/lib/loupe.ts';
import CanonButton from '../src/components/canon-button.tsx';
import CanonCanvas from '../src/components/canon-canvas.tsx';
import CanonColourCard from '../src/components/canon-colour-card.tsx';
import CanonColourControls, {
	useCanonColourSolidState,
} from '../src/components/canon-colour-controls.tsx';
import CanonColourNotationInput from '../src/components/canon-colour-notation-input.tsx';
import CanonColourSolid from '../src/components/canon-colour-solid.tsx';
import CanonColourStrip from '../src/components/canon-colour-strip.tsx';
import CanonDetentWheel from '../src/components/canon-detent-wheel.tsx';
import CanonDetentWheelRow from '../src/components/canon-detent-wheel-row.tsx';
import CanonHeading from '../src/components/canon-heading.tsx';
import CanonIcon from '../src/components/canon-icon.tsx';
import CanonLoupe from '../src/components/canon-loupe.tsx';
import CanonPaletteCard from '../src/components/canon-palette-card.tsx';
import CanonRow from '../src/components/canon-row.tsx';
import CanonRows from '../src/components/canon-rows.tsx';
import CanonSegmented from '../src/components/canon-segmented.tsx';
import CanonSplit from '../src/components/canon-split.tsx';
import CanonSwitch from '../src/components/canon-switch.tsx';
import CanonValueLine from '../src/components/canon-value-line.tsx';
import copy from 'lucide-static/icons/copy.svg?raw';
import save from 'lucide-static/icons/download.svg?raw';
import share from 'lucide-static/icons/share.svg?raw';

// stand-in for the app's 4,926 colour names
const names: [string, Rgb][] = (
	[
		['Black', '000000'],
		['White', 'FFFFFF'],
		['Grey', '808080'],
		['Red', 'E53935'],
		['Orange', 'FB8C00'],
		['Yellow', 'FDD835'],
		['Olive', '808000'],
		['Green', '43A047'],
		['Forest', '1E6626'],
		['Teal', '00897B'],
		['Cyan', '00ACC1'],
		['Blue', '1E88E5'],
		['Navy', '1A237E'],
		['Purple', '8E24AA'],
		['Pink', 'D81B60'],
		['Brown', '6D4C41'],
		['Cream', 'FAF5E6'],
	] as const
).map(([name, code]) => [name, parseHex(code)!]);

function nameOf(code: string): string {
	const [r, g, b] = parseHex(code)!;
	let best = names[0]!;
	let distance = Infinity;
	for (const entry of names) {
		const [x, y, z] = entry[1];
		const d = (r - x) ** 2 + (g - y) ** 2 + (b - z) ** 2;
		if (d < distance) [best, distance] = [entry, d];
	}
	return best[0];
}

const closestName = (colour: Rgb) => nameOf(hex(colour));

function maxChroma(l: number, h: number): number {
	const radians = (h * Math.PI) / 180;
	let [low, high] = [0, 0.5];
	for (let i = 0; i < 24; i++) {
		const mid = (low + high) / 2;
		const inside = oklabToLinear(
			l,
			mid * Math.cos(radians),
			mid * Math.sin(radians),
		).every((v) => v >= -1e-5 && v <= 1 + 1e-5);
		if (inside) low = mid;
		else high = mid;
	}
	return low;
}

function inGamut(l: number, c: number, h: number): Rgb {
	const hue = ((h % 360) + 360) % 360;
	return fromOklch(l, Math.min(c, maxChroma(l, hue)), hue);
}

const views = ['Slice', 'Ortho', 'Cut'];
const harmonyKinds = ['Analogous', 'Split'];
const normal = [
	[1, 0, 0],
	[0, 1, 0],
	[0, 0, 1],
];
const deuteranopia = [
	[0.625, 0.375, 0],
	[0.7, 0.3, 0],
	[0, 0.3, 0.7],
];

const spaceName = (index: number) => spaceNames[solidSpaces[index]!];
const tintDigits = (character: string) =>
	/\d/.test(character)
		? 'var(--canon-primary)'
		: 'var(--canon-foreground)';

// the colour's shades around the middle pixel, as the iOS gallery draws them
function loupePixels(colour: Rgb): ImageData {
	const side = 15;
	const pixels = new ImageData(side, side);
	for (let y = 0; y < side; y++) {
		for (let x = 0; x < side; x++) {
			const toward = (x + y) % 2 === 0 ? 1 : 0;
			const by = (Math.abs(x - 7) + Math.abs(y - 7)) / 16;
			const at = (y * side + x) * 4;
			colour.forEach((channel, i) => {
				pixels.data[at + i] = Math.round(
					(channel + (toward - channel) * by) *
						255,
				);
			});
			pixels.data[at + 3] = 255;
		}
	}
	return pixels;
}

function placeLoupe(loupe: HTMLDivElement) {
	const box = loupe.parentElement!;
	const observer = new ResizeObserver(() => {
		const { clientWidth: width, clientHeight: height } = box;
		const spot = frame(
			{ x: width / 2, y: height / 2 + 60 },
			112,
			24,
			{ width, height },
			8,
		);
		loupe.style.insetInlineStart = `${spot.x}px`;
		loupe.style.insetBlockStart = `${spot.y}px`;
	});
	observer.observe(box);
	return () => observer.disconnect();
}

// ?colourSpace=<picker index>&colourRow=<0-3>&colourView=<0-2>&colourCrease: the starting state, as the iOS launch arguments
const query = new URLSearchParams(window.location.search);
const number = (key: string) => Number(query.get(key) ?? 0) || 0;
const startView = number('colourView');
const crease = query.has('colourCrease');

/** The port of CanonColourGalleryViewController: the solid, colour cards and palette cards, driven by one colour. */
export default function ColourPage() {
	const state = useCanonColourSolidState({
		space: query.has('colourSpace')
			? solidSpaces[number('colourSpace')]
			: 'hsl',
		activeRow: number('colourRow'),
		slices: startView !== 2,
		viewPlane: startView === 1,
	});
	const [view, setView] = useState(startView);
	const [split, setSplit] = useState(false);
	const [stripPalette, setStripPalette] = useState(false);
	const [showsDeuteranopia, setShowsDeuteranopia] = useState(false);

	const { colour } = state;
	const [l, c, h] = oklch(colour);
	const harmony = (split ? [0, 150, 210] : [0, 30, -30]).map((turn) =>
		inGamut(l, c, h + turn),
	);
	const shades = Array.from({ length: 9 }, (_, i) =>
		inGamut(0.95 - i * 0.085, c, h),
	);

	const showView = (index: number) => {
		setView(index);
		state.set({ slices: index !== 2, viewPlane: index === 1 });
	};

	const copyPalette = () =>
		void navigator.clipboard?.writeText(
			harmony.map(hex).join('\n'),
		);

	return (
		<CanonSplit
			className="gallery"
			halves
			collapsesTo={240}
			pictureMeetsCrease={crease}
			sidebar={
				<CanonCanvas
					aspect={1}
					maxHeight={640}
					background="var(--canon-muted)"
				>
					<div className="gallery-solid">
						<CanonColourSolid
							className="gallery-solid-picture"
							space={state.space}
							point={state.point}
							animated={
								state.animated
							}
							sliceAxis={
								state.sliceAxis
							}
							isOrtho={state.isOrtho}
							showsWhole={
								state.showsWhole
							}
							marks={harmony.slice(1)}
							vision={
								showsDeuteranopia
									? deuteranopia
									: normal
							}
							onChange={state.pick}
							closestName={
								closestName
							}
						/>
						<CanonColourStrip
							colour={colour}
							palette={
								stripPalette
									? harmony
									: undefined
							}
							nameOf={nameOf}
						/>
					</div>
				</CanonCanvas>
			}
			main={
				<>
					<CanonRows framed>
						<CanonHeading text="Solid" />
						<CanonColourControls
							state={state}
						>
							<CanonRow
								title="View"
								form="flush"
							>
								<CanonSegmented
									items={
										views
									}
									selected={
										view
									}
									onChange={
										showView
									}
								/>
							</CanonRow>
						</CanonColourControls>
						<CanonRow title="Strip palette">
							{(titleId) => (
								<CanonSwitch
									on={
										stripPalette
									}
									onChange={
										setStripPalette
									}
									aria-labelledby={
										titleId
									}
								/>
							)}
						</CanonRow>
						<CanonRow title="Deuteranopia">
							{(titleId) => (
								<CanonSwitch
									on={
										showsDeuteranopia
									}
									onChange={
										setShowsDeuteranopia
									}
									aria-labelledby={
										titleId
									}
								/>
							)}
						</CanonRow>
					</CanonRows>
					<CanonColourCard
						colour={colour}
						nameOf={nameOf}
					/>
					<CanonColourCard
						colour={colour}
						layout="row"
						nameOf={nameOf}
					/>
					<CanonRows framed>
						<CanonHeading text="Value lines" />
						<CanonValueLine
							label="Decimal RGB"
							value={`rgb(${colour.map((v) => v.toFixed(4)).join(', ')})`}
							labelWidth={92}
						/>
						<CanonValueLine
							label="Luminance"
							value={luminance(
								colour,
							).toFixed(3)}
							labelWidth={92}
						/>
						<CanonValueLine
							label="Above"
							value={hex(colour)}
							layout="above"
						/>
						<CanonValueLine
							label="x ="
							value={hex(
								colour,
							).repeat(4)}
							layout="wrapping"
						/>
						<CanonValueLine
							label="Nil"
							value={null}
							layout="wrapping"
						/>
						<CanonValueLine
							label="01"
							value={hex(colour)}
							layout="numbered"
							lit
						/>
						<CanonValueLine
							label="02"
							value={hex(
								colour,
							).repeat(5)}
							layout="numbered"
							wraps
							tint={tintDigits}
						/>
					</CanonRows>
					<CanonRows framed>
						<CanonHeading text="Notation input" />
						<CanonRow
							title="Any notation"
							form="stacked"
						>
							{(titleId) => (
								<CanonColourNotationInput
									colour={
										colour
									}
									onColour={
										state.use
									}
									labelledBy={
										titleId
									}
								/>
							)}
						</CanonRow>
						<CanonHeading text="Loupe" />
						<CanonCanvas
							height={200}
							background="var(--canon-muted)"
						>
							<CanonLoupe
								className="gallery-loupe"
								pixels={loupePixels(
									colour,
								)}
								colour={colour}
								ref={placeLoupe}
							/>
						</CanonCanvas>
						<CanonHeading text="Detent wheel" />
						<CanonCanvas height={200}>
							<CanonDetentWheel
								count={
									solidSpaces.length
								}
								selected={solidSpaces.indexOf(
									state.space,
								)}
								onSelect={(
									index,
								) =>
									state.selectSpace(
										solidSpaces[
											index
										]!,
									)
								}
								text={spaceName}
								label="Space"
							>
								{(
									index,
									focus,
								) => (
									<CanonDetentWheelRow
										focus={
											focus
										}
									>
										{spaceName(
											index,
										)}
									</CanonDetentWheelRow>
								)}
							</CanonDetentWheel>
						</CanonCanvas>
					</CanonRows>
					<CanonPaletteCard
						title="Harmony"
						colours={harmony}
						nameOf={nameOf}
						picker={
							<CanonSegmented
								items={
									harmonyKinds
								}
								selected={
									split
										? 1
										: 0
								}
								onChange={(
									index,
								) =>
									setSplit(
										index ===
											1,
									)
								}
							/>
						}
						actions={
							<>
								<CanonButton
									text="Copy"
									icon={
										<CanonIcon
											svg={
												copy
											}
										/>
									}
									kind="cell"
									flashesCopied
									onClick={
										copyPalette
									}
								/>
								<CanonButton
									text="Export"
									icon={
										<CanonIcon
											svg={
												share
											}
										/>
									}
									kind="cell"
								/>
								<CanonButton
									text="Save"
									icon={
										<CanonIcon
											svg={
												save
											}
										/>
									}
									kind="cell"
								/>
							</>
						}
					/>
					<CanonPaletteCard
						title="Shades"
						colours={shades}
						height={120}
						nameOf={nameOf}
					/>
				</>
			}
		/>
	);
}
