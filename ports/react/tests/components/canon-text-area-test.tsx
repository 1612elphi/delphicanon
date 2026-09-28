import { describe, expect, test } from 'vitest';
import CanonTextArea from '../../src/components/canon-text-area.tsx';
import { fillIn, find, render } from '../helpers/render.tsx';

describe('canon-text-area', () => {
  test('reports typing; a new value does not replace text being typed', async () => {
    const edits: string[] = [];
    const record = (value: string) => edits.push(value);
    const area = (text: string) => (
      <CanonTextArea
        value={text}
        height={120}
        placeholder="Notes"
        aria-label="Notes"
        onChange={record}
      />
    );
    const { rerender } = await render(area('one'));
    const field = find<HTMLTextAreaElement>('textarea');
    expect(field.value).toBe('one');
    expect(field.offsetHeight).toBe(120);
    await fillIn('textarea', 'typed');
    expect(edits).toEqual(['typed']);
    await rerender(area('echo'));
    expect(field.value, 'focused: kept').toBe('typed');
    field.blur();
    await rerender(area('later'));
    expect(field.value).toBe('later');
  });
});
