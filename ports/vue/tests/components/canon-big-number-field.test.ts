import { expect, test } from 'vitest';
import CanonBigNumberField from '../../src/components/canon-big-number-field.vue';
import {
	blur,
	click,
	fillIn,
	find,
	render,
	triggerKeyEvent,
} from '../helpers/render.ts';

test('steps, reports typing and the end of typing', async () => {
	const steps: number[] = [];
	const typed: string[] = [];
	let ended = 0;
	const step = (direction: -1 | 1) => steps.push(direction);
	const typing = (text: string) => typed.push(text);
	const end = () => ended++;
	await render(
		`<CanonBigNumberField
      value="16"
      placeholder="0"
      unit="PX"
      label="Size"
      :on-step="step"
      :on-input="typing"
      :on-end-editing="end"
    />`,
		{ CanonBigNumberField, step, typing, end },
	);
	expect(find('input')).toHaveValue('16');
	expect(find('input')).toHaveAttribute('inputmode', 'decimal');
	expect(find('.canon-big-number-field-unit').textContent?.trim()).toBe(
		'PX',
	);
	await click('.canon-stepper-plus');
	await click('.canon-stepper-minus');
	await triggerKeyEvent('input', 'keydown', 'ArrowUp');
	expect(steps).toEqual([1, -1, 1]);
	await fillIn('input', '24');
	await blur('input');
	expect(typed).toEqual(['24']);
	expect(ended).toBe(1);
});
