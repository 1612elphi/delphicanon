import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import { repeatTiming } from '../src/components/canon-button.svelte';
import Stepper from './fixtures/canon-stepper-field.svelte';
import { click, find, triggerEvent, wait } from './helpers.ts';

test('minus and plus step once per tap', async () => {
  const steps: number[] = [];
  await render(Stepper, { onStep: (direction) => steps.push(direction) });
  expect(find('.canon-stepper-minus').getAttribute('aria-label')).toBe(
    'Decrease',
  );
  await click('.canon-stepper-minus');
  await click('.canon-stepper-plus');
  expect(steps).toEqual([-1, 1]);
});

test('a held button repeats after the delay, then every interval', async () => {
  let steps = 0;
  await render(Stepper, { onStep: () => (steps += 1) });
  await triggerEvent('.canon-stepper-plus', 'pointerdown', { button: 0 });
  await wait(repeatTiming.delay * 1000 - 100);
  expect(steps, 'nothing before the delay').toBe(0);
  await wait(100 + repeatTiming.interval * 1000 * 3);
  await triggerEvent('.canon-stepper-plus', 'pointerup', { button: 0 });
  // timers run late under load, never early
  expect(steps).toBeGreaterThanOrEqual(2);
  expect(steps).toBeLessThanOrEqual(4);
});

test('a click in the middle cell focuses the field', async () => {
  await render(Stepper, { onStep: () => undefined });
  await click('.canon-stepper-centre');
  expect(document.activeElement).toBe(find('input'));
});
