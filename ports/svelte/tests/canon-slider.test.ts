import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonSlider from '../src/components/canon-slider.svelte';
import { find, triggerEvent, triggerKeyEvent } from './helpers.ts';

const whole = (value: number) => String(Math.round(value));

test('shows the readout and steps from the keyboard', async () => {
	const values: number[] = [];
	await render(CanonSlider, {
		value: 99.4,
		min: 1,
		max: 100,
		step: 1,
		readout: whole,
		label: 'Level',
		onChange: (value) => values.push(value),
	});
	expect(find('.canon-slider').getAttribute('role')).toBe('slider');
	expect(find('.canon-slider-readout').textContent).toBe('99');
	await triggerKeyEvent('.canon-slider', 'keydown', 'ArrowRight');
	await triggerKeyEvent('.canon-slider', 'keydown', 'ArrowRight');
	expect(values, 'stops at the top').toEqual([100]);
	await triggerKeyEvent('.canon-slider', 'keydown', 'Home');
	expect(find('.canon-slider').getAttribute('aria-valuenow')).toBe('1');
});

test('a tap on the track sets the value', async () => {
	const { container } = await render(CanonSlider, {
		value: 0.2,
		label: 'Mix',
	});
	container.style.width = '300px';
	const track = find('.canon-slider-track').getBoundingClientRect();
	const at = {
		button: 0,
		pointerId: 1,
		clientX: track.left + track.width * 0.75,
		clientY: track.top + track.height / 2,
	};
	await triggerEvent('.canon-slider', 'pointerdown', at);
	await triggerEvent('.canon-slider', 'pointerup', at);
	expect(find('.canon-slider-readout').textContent).toBe('75%');
});

test('a new range clamps the value', async () => {
	await render(CanonSlider, { value: 8, max: 5, label: 'Gain' });
	expect(find('.canon-slider').getAttribute('aria-valuenow')).toBe('5');
});

test('a sideways drag reports dragging; the consumer pointerdown runs too', async () => {
	const calls: [number, boolean][] = [];
	let downs = 0;
	const { container } = await render(CanonSlider, {
		value: 0.2,
		label: 'Mix',
		onChange: (value, dragging) => calls.push([value, dragging]),
		onpointerdown: () => (downs += 1),
	});
	container.style.width = '300px';
	const track = find('.canon-slider-track').getBoundingClientRect();
	const y = track.top + track.height / 2;
	const x = track.left + track.width * 0.5;
	await triggerEvent('.canon-slider', 'pointerdown', {
		button: 0,
		clientX: x,
		clientY: y,
	});
	await triggerEvent('.canon-slider', 'pointermove', {
		clientX: x + 30,
		clientY: y,
	});
	await triggerEvent('.canon-slider', 'pointerup', {
		clientX: x + 30,
		clientY: y,
	});
	expect(downs).toBe(1);
	expect(calls.length).toBe(1);
	expect(calls[0]?.[1]).toBe(true);
});
