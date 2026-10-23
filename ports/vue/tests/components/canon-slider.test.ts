import { expect, test } from 'vitest';
import CanonSlider from '../../src/components/canon-slider.vue';
import {
	find,
	render,
	triggerEvent,
	triggerKeyEvent,
} from '../helpers/render.ts';

const whole = (value: number) => String(Math.round(value));

test('shows the readout and steps from the keyboard', async () => {
	const values: number[] = [];
	const record = (value: number) => values.push(value);
	await render(
		`<CanonSlider
      :value="99.4"
      :min="1"
      :max="100"
      :step="1"
      :readout="whole"
      label="Level"
      :on-change="record"
    />`,
		{ CanonSlider, whole, record },
	);
	expect(find('.canon-slider')).toHaveAttribute('role', 'slider');
	expect(find('.canon-slider-readout').textContent?.trim()).toBe('99');
	await triggerKeyEvent('.canon-slider', 'keydown', 'ArrowRight');
	await triggerKeyEvent('.canon-slider', 'keydown', 'ArrowRight');
	expect(values, 'stops at the top').toEqual([100]);
	await triggerKeyEvent('.canon-slider', 'keydown', 'Home');
	expect(find('.canon-slider')).toHaveAttribute('aria-valuenow', '1');
});

test('a tap on the track sets the value', async () => {
	await render(
		`<div style="width: 300px"><CanonSlider :value="0.2" label="Mix" /></div>`,
		{ CanonSlider },
	);
	const track = find('.canon-slider-track').getBoundingClientRect();
	const at = {
		button: 0,
		pointerId: 1,
		clientX: track.left + track.width * 0.75,
		clientY: track.top + track.height / 2,
	};
	await triggerEvent('.canon-slider', 'pointerdown', at);
	await triggerEvent('.canon-slider', 'pointerup', at);
	expect(find('.canon-slider-readout').textContent?.trim()).toBe('75%');
});

test('a new range clamps the value', async () => {
	await render(`<CanonSlider :value="8" :max="5" label="Gain" />`, {
		CanonSlider,
	});
	expect(find('.canon-slider')).toHaveAttribute('aria-valuenow', '5');
});
