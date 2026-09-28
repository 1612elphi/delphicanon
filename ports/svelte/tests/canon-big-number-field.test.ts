import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonBigNumberField from '../src/components/canon-big-number-field.svelte';
import { blur, click, fillIn, find, triggerKeyEvent } from './helpers.ts';

test('steps, reports typing and the end of typing', async () => {
  const steps: number[] = [];
  const typed: string[] = [];
  let ended = 0;
  await render(CanonBigNumberField, {
    value: '16',
    placeholder: '0',
    unit: 'PX',
    label: 'Size',
    onStep: (direction) => steps.push(direction),
    onInput: (text) => typed.push(text),
    onEndEditing: () => ended++,
  });
  const input = find<HTMLInputElement>('input');
  expect(input.value).toBe('16');
  expect(input.getAttribute('inputmode')).toBe('decimal');
  expect(find('.canon-big-number-field-unit').textContent).toBe('PX');
  await click('.canon-stepper-plus');
  await click('.canon-stepper-minus');
  await triggerKeyEvent('input', 'keydown', 'ArrowUp');
  expect(steps).toEqual([1, -1, 1]);
  await fillIn('input', '24');
  await blur('input');
  expect(typed).toEqual(['24']);
  expect(ended).toBe(1);
});
