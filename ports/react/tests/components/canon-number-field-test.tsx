import { describe, expect, test } from 'vitest';
import CanonNumberField from '../../src/components/canon-number-field.tsx';
import { blur, click, fillIn, find, key, render } from '../helpers/render.tsx';

describe('canon-number-field', () => {
  test('clamps, steps and takes typed integers in range', async () => {
    const values: number[] = [];
    const record = (value: number) => values.push(value);
    await render(
      <CanonNumberField
        value={9000}
        max={5000}
        step={50}
        unit="items"
        label="Count"
        onChange={record}
      />,
    );
    const input = () => find<HTMLInputElement>('input');
    expect(input().value).toBe('5000');
    expect(input().getAttribute('role')).toBe('spinbutton');
    expect(find('.canon-stepper-unit').textContent).toBe('items');
    await click('.canon-stepper-plus');
    expect(values, 'at the top, plus does nothing').toEqual([]);
    await click('.canon-stepper-minus');
    expect(input().value).toBe('4950');
    await fillIn('input', '12');
    await fillIn('input', '9999');
    await key('input', 'ArrowUp');
    await blur('input');
    expect(values).toEqual([4950, 12, 62]);
    expect(input().value).toBe('62');
  });
});
