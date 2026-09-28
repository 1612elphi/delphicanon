import { describe, expect, test } from 'vitest';
import CanonDecimalField from '../../src/components/canon-decimal-field.tsx';
import { blur, click, fillIn, find, render } from '../helpers/render.tsx';

describe('canon-decimal-field', () => {
  test('steps in tenths and commits typing on blur', async () => {
    const values: number[] = [];
    const record = (value: number) => values.push(value);
    await render(
      <CanonDecimalField value={1.5} label="Start" onChange={record} />,
    );
    const input = () => find<HTMLInputElement>('input');
    expect(input().value).toBe('1.5');
    expect(find('.canon-stepper-unit').textContent).toBe('s');
    await click('.canon-stepper-plus');
    expect(input().value).toBe('1.6');
    await fillIn('input', '2,34567');
    await blur('input');
    expect(values).toEqual([1.6, 2.346]);
    expect(input().value).toBe('2.346');
    await click('.canon-stepper-minus');
    await fillIn('input', '-3');
    await blur('input');
    expect(values.at(-1), 'unsigned stops at 0').toBe(0);
  });
});
