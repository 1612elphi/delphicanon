import { expect, test } from 'vitest';
import CanonNumberField from '../../src/components/canon-number-field.vue';
import {
  blur,
  click,
  fillIn,
  find,
  render,
  triggerKeyEvent,
} from '../helpers/render.ts';

test('clamps, steps and takes typed integers in range', async () => {
  const values: number[] = [];
  const record = (value: number) => values.push(value);
  await render(
    `<CanonNumberField
      :value="9000"
      :max="5000"
      :step="50"
      unit="items"
      label="Count"
      :on-change="record"
    />`,
    { CanonNumberField, record },
  );
  expect(find('input')).toHaveValue('5000');
  expect(find('input')).toHaveAttribute('role', 'spinbutton');
  expect(find('.canon-stepper-unit').textContent?.trim()).toBe('items');
  await click('.canon-stepper-plus');
  expect(values, 'at the top, plus does nothing').toEqual([]);
  await click('.canon-stepper-minus');
  expect(find('input')).toHaveValue('4950');
  await fillIn('input', '12');
  await fillIn('input', '9999');
  await triggerKeyEvent('input', 'keydown', 'ArrowUp');
  await blur('input');
  expect(values).toEqual([4950, 12, 62]);
  expect(find('input')).toHaveValue('62');
});
