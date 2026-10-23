import { useState } from 'react';
import { describe, expect, test } from 'vitest';
import CanonColourSolid from '../../src/components/canon-colour-solid.tsx';
import type { Rgb } from '@canon/lib/colour.ts';
import type { SolidSpace as Space } from '@canon/lib/colour-space.ts';
import type { Vec4 } from '@canon/lib/colour-solid/vec.ts';
import {
	find,
	findAll,
	key,
	render,
	settle,
	trigger,
} from '../helpers/render.tsx';

const frame = () => new Promise((resolve) => requestAnimationFrame(resolve));
const hasWebGL2 = !!document.createElement('canvas').getContext('webgl2');

async function until(condition: () => boolean) {
	const end = performance.now() + 1000;
	while (!condition()) {
		if (performance.now() > end)
			throw new Error('condition not met');
		await settle(frame);
	}
}

function pixel(canvas: HTMLCanvasElement, x: number, y: number) {
	const gl = canvas.getContext('webgl2')!;
	const out = new Uint8Array(4);
	gl.readPixels(
		x,
		canvas.height - 1 - y,
		1,
		1,
		gl.RGBA,
		gl.UNSIGNED_BYTE,
		out,
	);
	return [...out];
}

interface Model {
	picks: Vec4[];
	colours: Rgb[];
}

function Solid({
	model,
	space,
	initial,
	size,
}: {
	model: Model;
	space: Space;
	initial: Vec4;
	size: number;
}) {
	const [point, setPoint] = useState<Vec4>(initial);
	return (
		<div style={{ width: size, height: size }}>
			<CanonColourSolid
				space={space}
				point={point}
				onChange={(next, colour) => {
					model.picks.push(next);
					model.colours.push(colour);
					setPoint(next);
				}}
			/>
		</div>
	);
}

describe('canon-colour-solid', () => {
	test('draws the solid, marks the pick, picks on a tap', async () => {
		const model: Model = { picks: [], colours: [] };
		await render(
			<Solid
				model={model}
				space="rgb"
				initial={[0.5, 0.5, 0.5, 0]}
				size={300}
			/>,
		);
		await settle(frame);
		expect(
			find('.canon-colour-solid').getAttribute('aria-label'),
		).toBe('RGB');
		expect(find('.canon-colour-solid output').textContent).toBe(
			'#808080',
		);
		expect(
			find(
				'.canon-colour-solid-marker--pick',
			).getClientRects().length,
		).toBeGreaterThan(0);
		expect(findAll('.canon-colour-solid-axis')).toHaveLength(3);

		const canvas = find<HTMLCanvasElement>(
			'.canon-colour-solid-canvas',
		);
		if (hasWebGL2) {
			expect(find('.canon-colour-solid').dataset['gl']).toBe(
				'ready',
			);
			expect(canvas.width).toBe(
				Math.round(300 * devicePixelRatio),
			);
			const middle = Math.round(canvas.width * 0.6);
			expect(
				pixel(canvas, middle, middle)[3],
				'the cube is opaque',
			).toBe(255);
			expect(
				pixel(canvas, 1, 1)[3],
				'around it is clear',
			).toBe(0);
		} else {
			expect(find('.canon-colour-solid').dataset['gl']).toBe(
				'none',
			);
		}

		const solid = find('.canon-colour-solid');
		const box = solid.getBoundingClientRect();
		const at = {
			clientX: box.left + box.width * 0.62,
			clientY: box.top + box.height * 0.62,
			button: 0,
			pointerId: 1,
		};
		await trigger(solid, 'pointerdown', at);
		await trigger(solid, 'pointerup', at);
		expect(model.picks, 'a tap on the cube picks').toHaveLength(1);
		await until(() => find('output').textContent !== '#808080');
		expect(find('output').textContent).toMatch(/^#[0-9A-F]{6}$/);
	});

	test('a new space converts the pick; arrow keys turn it', async () => {
		const model: Model = { picks: [], colours: [] };
		const solid = (space: Space) => (
			<Solid
				model={model}
				space={space}
				initial={[1, 0, 0, 0]}
				size={200}
			/>
		);
		const { rerender } = await render(solid('rgb'));
		await rerender(solid('hsl'));
		await until(() => model.picks.length > 0);
		expect(model.picks[0], 'red in HSL').toEqual([0, 0.5, 1, 0]);
		expect(
			find('.canon-colour-solid').getAttribute('aria-label'),
		).toBe('HSL');

		const marker = find('.canon-colour-solid-marker--pick');
		const before = marker.style.translate;
		await key('.canon-colour-solid', 'ArrowRight');
		await settle(frame);
		await settle(frame);
		expect(
			marker.style.translate,
			'the pick moves with the turn',
		).not.toBe(before);
	});
});
