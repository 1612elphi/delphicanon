import { expect, test } from 'vitest';
import CanonTextCell from '../../src/components/canon-text-cell.vue';
import { fillIn, find, render, triggerKeyEvent } from '../helpers/render.ts';

test('reports every edit; Enter leaves the field', async () => {
  const edits: string[] = [];
  const record = (value: string) => edits.push(value);
  await render(
    `<CanonTextCell placeholder="Trigger" aria-label="Trigger" :on-change="record" />`,
    { CanonTextCell, record },
  );
  expect(find('input')).toHaveAttribute('placeholder', 'Trigger');
  expect(find('.canon-text-cell').offsetHeight).toBe(44);
  await fillIn('input', 'go');
  expect(edits).toEqual(['go']);
  await triggerKeyEvent('input', 'keydown', 'Enter');
  expect(find('input')).not.toHaveFocus();
});
