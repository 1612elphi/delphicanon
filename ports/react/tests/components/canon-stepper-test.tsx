import { describe, expect, test } from 'vitest';
import CanonStepper from '../../src/components/canon-stepper.tsx';
import { repeatTiming } from '../../src/components/canon-button.tsx';
import { click, find, render, trigger, wait } from '../helpers/render.tsx';

describe('canon-stepper', () => {
	test('minus and plus step once per tap', async () => {
		const steps: number[] = [];
		const step = (direction: number) => steps.push(direction);
		await render(
			<CanonStepper onStep={step}>
				<input aria-label="n" />
			</CanonStepper>,
		);
		expect(
			find('.canon-stepper-minus').getAttribute('aria-label'),
		).toBe('Decrease');
		await click('.canon-stepper-minus');
		await click('.canon-stepper-plus');
		expect(steps).toEqual([-1, 1]);
	});

	test('a held button repeats after the delay, then every interval', async () => {
		let steps = 0;
		const step = () => (steps += 1);
		await render(
			<CanonStepper onStep={step}>
				<input aria-label="n" />
			</CanonStepper>,
		);
		await trigger('.canon-stepper-plus', 'pointerdown', {
			button: 0,
		});
		await wait(repeatTiming.delay * 1000 - 100);
		expect(steps, 'nothing before the delay').toBe(0);
		await wait(100 + repeatTiming.interval * 1000 * 3);
		await trigger('.canon-stepper-plus', 'pointerup', {
			button: 0,
		});
		// timers run late under load, never early
		expect(steps).toBeGreaterThanOrEqual(2);
		expect(steps).toBeLessThanOrEqual(4);
	});

	test('a click in the middle cell focuses the field', async () => {
		await render(
			<CanonStepper onStep={() => undefined}>
				<input aria-label="n" />
			</CanonStepper>,
		);
		await click('.canon-stepper-centre');
		expect(document.activeElement).toBe(find('input'));
	});
});
