import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonNumberField from '../src/components/canon-number-field.svelte';
import { blur, click, fillIn, find, triggerKeyEvent } from './helpers.ts';

test('clamps, steps and takes typed integers in range', async () => {
  const values: number[] = [];
  await render(CanonNumberField, {
    value: 9000,
    max: 5000,
    step: 50,
    unit: 'items',
    label: 'Count',
    onChange: (value) => values.push(value),
  });
  const input = find<HTMLInputElement>('input');
  expect(input.value).toBe('5000');
  expect(input.getAttribute('role')).toBe('spinbutton');
  expect(find('.canon-stepper-unit').textContent).toBe('items');
  await click('.canon-stepper-plus');
  expect(values, 'at the top, plus does nothing').toEqual([]);
  await click('.canon-stepper-minus');
  expect(input.value).toBe('4950');
  await fillIn('input', '12');
  await fillIn('input', '9999');
  await triggerKeyEvent('input', 'keydown', 'ArrowUp');
  await blur('input');
  expect(values).toEqual([4950, 12, 62]);
  expect(input.value).toBe('62');
});
