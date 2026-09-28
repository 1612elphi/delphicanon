import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonTextArea from '../src/components/canon-text-area.svelte';
import { fillIn, find, settled } from './helpers.ts';

test('reports typing; a new value does not replace text being typed', async () => {
  const edits: string[] = [];
  const { rerender } = await render(CanonTextArea, {
    value: 'one',
    height: 120,
    placeholder: 'Notes',
    'aria-label': 'Notes',
    onChange: (value) => edits.push(value),
  });
  const area = find<HTMLTextAreaElement>('textarea');
  expect(area.value).toBe('one');
  expect(area.offsetHeight).toBe(120);
  await fillIn('textarea', 'typed');
  expect(edits).toEqual(['typed']);
  await rerender({ value: 'echo' });
  await settled();
  expect(area.value, 'focused: kept').toBe('typed');
  area.blur();
  await rerender({ value: 'later' });
  await settled();
  expect(area.value).toBe('later');
});
