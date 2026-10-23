import { expect, test } from 'vitest';
import CanonStepper from '../../src/components/canon-stepper.vue';
import { repeatTiming } from '../../src/components/canon-button.vue';
import { click, find, render, triggerEvent, wait } from '../helpers/render.ts';

test('minus and plus step once per tap', async () => {
	const steps: number[] = [];
	const step = (direction: number) => steps.push(direction);
	await render(
		`<CanonStepper :on-step="step"><input aria-label="n" /></CanonStepper>`,
		{ CanonStepper, step },
	);
	expect(find('.canon-stepper-minus')).toHaveAttribute(
		'aria-label',
		'Decrease',
	);
	await click('.canon-stepper-minus');
	await click('.canon-stepper-plus');
	expect(steps).toEqual([-1, 1]);
});

test('a held button repeats after the delay, then every interval', async () => {
	let steps = 0;
	const step = () => (steps += 1);
	await render(
		`<CanonStepper :on-step="step"><input aria-label="n" /></CanonStepper>`,
		{ CanonStepper, step },
	);
	await triggerEvent('.canon-stepper-plus', 'pointerdown', { button: 0 });
	await wait(repeatTiming.delay * 1000 - 100);
	expect(steps, 'nothing before the delay').toBe(0);
	await wait(100 + repeatTiming.interval * 1000 * 3);
	await triggerEvent('.canon-stepper-plus', 'pointerup', { button: 0 });
	// timers run late under load, never early
	expect(steps >= 2 && steps <= 4, `${steps} steps`).toBe(true);
});

test('a click in the middle cell focuses the field', async () => {
	const step = () => undefined;
	await render(
		`<CanonStepper :on-step="step"><input aria-label="n" /></CanonStepper>`,
		{ CanonStepper, step },
	);
	await click('.canon-stepper-centre');
	expect(find('input')).toHaveFocus();
});
