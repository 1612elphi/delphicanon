import { describe, expect, test } from 'vitest';
import CanonTextCell from '../../src/components/canon-text-cell.tsx';
import { fillIn, find, key, render } from '../helpers/render.tsx';

describe('canon-text-cell', () => {
  test('reports every edit; Enter leaves the field', async () => {
    const edits: string[] = [];
    const record = (value: string) => edits.push(value);
    await render(
      <CanonTextCell
        placeholder="Trigger"
        aria-label="Trigger"
        onChange={record}
      />,
    );
    expect(find('input').getAttribute('placeholder')).toBe('Trigger');
    expect(find('.canon-text-cell').offsetHeight).toBe(44);
    await fillIn('input', 'go');
    expect(edits).toEqual(['go']);
    await key('input', 'Enter');
    expect(document.activeElement).not.toBe(find('input'));
  });

  test('an edit the consumer does not echo stays; a new value replaces it', async () => {
    const { rerender } = await render(<CanonTextCell value="one" />);
    expect(find<HTMLInputElement>('input').value).toBe('one');
    await fillIn('input', 'typed');
    expect(find<HTMLInputElement>('input').value).toBe('typed');
    await rerender(<CanonTextCell value="two" />);
    expect(find<HTMLInputElement>('input').value).toBe('two');
  });
});
