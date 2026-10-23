import type { HTMLAttributes, ReactNode } from 'react';
import { cx } from '../lib/class-names.ts';
import CanonLamps, { transportLamps, type CanonLamp } from './canon-lamps.tsx';
import CanonTimecode from './canon-timecode.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-readout-band.css';

/** What a readout band shows of a player. */
export interface CanonTransport {
	playhead?: number | null;
	playing?: boolean;
	/** Parked at `playhead`. */
	paused?: boolean;
	/** Capturing, for a record lamp. */
	recording?: boolean;
	looping?: boolean;
	/** Count of wraps; a change blinks the loop lamp. */
	loops?: number;
}

export interface CanonReadoutBandProps extends Omit<
	HTMLAttributes<HTMLDivElement>,
	'children'
> {
	transport: CanonTransport;
	/** Seconds the counter shows without a playhead; none shows hyphens. */
	idle?: number | null;
	/**
	 * over: counter and lamps sit over the strip's bottom corners, a waveform
	 * reads through them. below: they get a row of their own under the strip,
	 * a filmstrip's frames stay clear.
	 */
	readout?: 'over' | 'below';
	/** Which lamps the band has; every one is always present. */
	lamps?: readonly CanonLamp[];
	/** See CanonTimecode's `format`. */
	format?: (seconds: number) => string;
	/** The picture of the whole file: a waveform, a filmstrip. A function gets the playhead. */
	children?:
		| ReactNode
		| ((playhead: number | null | undefined) => ReactNode);
}

/** Height of the row under the strip in `below`. */
export const readoutRow = 44;

/** The band's height for a strip of a given height, in `below`. */
export function readoutBandHeight(strip: number) {
	return strip + readoutRow;
}

/** A strip of the whole file under a counter and transport lamps: the banner of a media tool. */
export default function CanonReadoutBand({
	transport,
	idle,
	readout = 'over',
	lamps,
	format,
	children,
	className,
	...rest
}: CanonReadoutBandProps) {
	const { playhead, playing, paused, looping, recording, loops } =
		transport;
	const lit: CanonLamp[] = [];
	if (playing) lit.push('play');
	if (paused) lit.push('pause');
	if (looping) lit.push('loop');
	if (recording) lit.push('record');
	const parked = playhead === undefined || playhead === null;

	return (
		<div
			className={cx(
				'canon-readout-band',
				`canon-readout-band--${readout}`,
				className,
			)}
			{...rest}
		>
			<div className="canon-readout-band-strip">
				{typeof children === 'function'
					? children(playhead)
					: children}
			</div>
			<div className="canon-readout-band-readout">
				<CanonLamps
					lamps={
						lamps?.length
							? lamps
							: transportLamps
					}
					lit={lit}
					flashes={{ loop: loops ?? 0 }}
				/>
				<CanonTimecode
					seconds={playhead ?? idle}
					format={format}
					size={readout === 'over' ? 44 : 30}
					label={parked ? 'Length' : 'Position'}
				/>
			</div>
		</div>
	);
}
