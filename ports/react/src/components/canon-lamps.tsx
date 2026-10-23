import { useEffect, useRef, type HTMLAttributes } from 'react';
import { cx } from '../lib/class-names.ts';
import { CircleDot, Pause, Play, Repeat } from '../lib/control-icons.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-lamps.css';

export type CanonLamp = 'play' | 'pause' | 'loop' | 'record';

export interface CanonLampsProps extends HTMLAttributes<HTMLSpanElement> {
	/** Which lamps; every one is always present. Default play, pause, loop. */
	lamps?: readonly CanonLamp[];
	lit?: readonly CanonLamp[];
	/** A count per lamp; each change turns that lamp off for a split second. */
	flashes?: Partial<Record<CanonLamp, number>>;
}

export const transportLamps: CanonLamp[] = ['play', 'pause', 'loop'];

/** Milliseconds a lamp stays unlit when it blinks. */
export const lampBlinkMs = 120;

const icons = { play: Play, pause: Pause, loop: Repeat, record: CircleDot };

function Lamp({
	lamp,
	lit,
	flashes = 0,
}: {
	lamp: CanonLamp;
	lit: boolean;
	flashes?: number;
}) {
	const element = useRef<HTMLSpanElement>(null);
	const last = useRef(flashes);
	const Icon = icons[lamp];

	useEffect(() => {
		const lampElement = element.current;
		if (!lampElement || last.current === flashes) return;
		last.current = flashes;
		lampElement.classList.add('canon-lamps-lamp--blink');
		const timer = window.setTimeout(
			() =>
				lampElement.classList.remove(
					'canon-lamps-lamp--blink',
				),
			lampBlinkMs,
		);
		return () => window.clearTimeout(timer);
	}, [flashes]);

	return (
		<span
			className={cx(
				'canon-lamps-lamp',
				`canon-lamps-lamp--${lamp}`,
				lit && 'canon-lamps-lamp--lit',
			)}
			ref={element}
		>
			<Icon />
		</span>
	);
}

/** Transport lamps: every icon is always present, lit while its state holds. Record lights red. */
export default function CanonLamps({
	lamps,
	lit,
	flashes,
	className,
	...rest
}: CanonLampsProps) {
	return (
		<span
			className={cx('canon-lamps', className)}
			aria-hidden="true"
			{...rest}
		>
			{(lamps?.length ? lamps : transportLamps).map(
				(lamp) => (
					<Lamp
						key={lamp}
						lamp={lamp}
						lit={
							lit?.includes(lamp) ??
							false
						}
						flashes={flashes?.[lamp]}
					/>
				),
			)}
		</span>
	);
}
