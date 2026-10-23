import { describe, expect, test } from 'vitest';
import {
	useGrabPan,
	useSidewaysPan,
	type GrabPanHandlers,
	type PanHandlers,
} from '../../src/lib/pans.ts';
import { find, render, trigger } from '../helpers/render.tsx';

const point = (x: number, y: number) => ({
	pointerId: 1,
	button: 0,
	clientX: x,
	clientY: y,
});

const pad = { width: 200, height: 100 };

function SidewaysPad(handlers: PanHandlers) {
	return (
		<div
			className="pad"
			style={pad}
			ref={useSidewaysPan(handlers)}
		/>
	);
}

function GrabPad(handlers: GrabPanHandlers) {
	return <div className="pad" style={pad} ref={useGrabPan(handlers)} />;
}

describe('pans', () => {
	test('a sideways pan begins only on a clearly sideways drag', async () => {
		const moves: number[] = [];
		await render(
			<SidewaysPad
				onMove={(event) => moves.push(event.clientX)}
			/>,
		);
		expect(find('.pad').style.touchAction).toBe('pan-y');
		await trigger('.pad', 'pointerdown', point(10, 10));
		await trigger('.pad', 'pointermove', point(12, 20));
		await trigger('.pad', 'pointermove', point(40, 20));
		await trigger('.pad', 'pointerup', point(40, 20));
		expect(moves).toEqual([]);
		await trigger('.pad', 'pointerdown', point(10, 10));
		await trigger('.pad', 'pointermove', point(13, 10));
		await trigger('.pad', 'pointermove', point(30, 12));
		await trigger('.pad', 'pointermove', point(50, 12));
		expect(moves).toEqual([30, 50]);
	});

	test('a grab pan begins only where grabs says', async () => {
		const begun: number[] = [];
		await render(
			<GrabPad
				grabs={({ x }) => x < 50}
				onBegin={(event) => begun.push(event.clientX)}
			/>,
		);
		const box = find('.pad').getBoundingClientRect();
		await trigger(
			'.pad',
			'pointerdown',
			point(box.left + 150, box.top + 5),
		);
		await trigger(
			'.pad',
			'pointerup',
			point(box.left + 150, box.top + 5),
		);
		await trigger(
			'.pad',
			'pointerdown',
			point(box.left + 10, box.top + 5),
		);
		expect(begun).toEqual([box.left + 10]);
	});
});
