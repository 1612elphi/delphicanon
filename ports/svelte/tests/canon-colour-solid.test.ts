import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import type { Rgb } from '@canon/lib/colour.ts';
import type { Vec4 } from '@canon/lib/colour-solid/vec.ts';
import Model from './fixtures/canon-colour-solid-model.svelte';
import {
	find,
	findAll,
	nextFrame,
	settled,
	triggerEvent,
	triggerKeyEvent,
	waitUntil,
} from './helpers.ts';

const hasWebGL2 = !!document.createElement('canvas').getContext('webgl2');

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

function recorder() {
	const picks: Vec4[] = [];
	const colours: Rgb[] = [];
	const onChange = (point: Vec4, colour: Rgb) => {
		picks.push(point);
		colours.push(colour);
	};
	return { picks, colours, onChange };
}

describe('canon-colour-solid', () => {
	test('draws the solid, marks the pick, picks on a tap', async () => {
		const model = recorder();
		await render(Model, {
			size: 300,
			space: 'rgb',
			point: [0.5, 0.5, 0.5, 0],
			onChange: model.onChange,
		});
		await nextFrame();
		const solid = find('.canon-colour-solid');
		expect(solid.getAttribute('aria-label')).toBe('RGB');
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
			expect(solid.dataset['gl']).toBe('ready');
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
			expect(solid.dataset['gl']).toBe('none');
		}

		const box = solid.getBoundingClientRect();
		const at = {
			clientX: box.left + box.width * 0.62,
			clientY: box.top + box.height * 0.62,
			button: 0,
			pointerId: 1,
		};
		await triggerEvent(solid, 'pointerdown', at);
		await triggerEvent(solid, 'pointerup', at);
		expect(model.picks, 'a tap on the cube picks').toHaveLength(1);
		await waitUntil(
			() =>
				document.querySelector('output')
					?.textContent !== '#808080',
		);
		expect(find('output').textContent).toMatch(/^#[0-9A-F]{6}$/);
	});

	test('a new space converts the pick; arrow keys turn it', async () => {
		const model = recorder();
		const props = {
			size: 200,
			point: [1, 0, 0, 0] as Vec4,
			onChange: model.onChange,
		};
		const { rerender } = await render(Model, {
			...props,
			space: 'rgb',
		});
		await rerender({ ...props, space: 'hsl' });
		await settled();
		await waitUntil(() => model.picks.length > 0);
		expect(model.picks[0], 'red in HSL').toEqual([0, 0.5, 1, 0]);
		expect(
			find('.canon-colour-solid').getAttribute('aria-label'),
		).toBe('HSL');

		const marker = find('.canon-colour-solid-marker--pick');
		const before = marker.style.translate;
		await triggerKeyEvent(
			'.canon-colour-solid',
			'keydown',
			'ArrowRight',
		);
		await nextFrame();
		await nextFrame();
		expect(
			marker.style.translate,
			'the pick moves with the turn',
		).not.toBe(before);
	});
});
