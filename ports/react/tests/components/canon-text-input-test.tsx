import { describe, expect, test } from 'vitest';
import CanonTextInput from '../../src/components/canon-text-input.tsx';
import { click, fillIn, find, render, wait } from '../helpers/render.tsx';

describe('canon-text-input', () => {
  test('typing arrives after a pause, Clear at once', async () => {
    const seen: string[] = [];
    await render(
      <CanonTextInput value="Hi" onChange={(text) => seen.push(text)} />,
    );
    expect(find<HTMLTextAreaElement>('textarea').value).toBe('Hi');
    expect(find('textarea').getAttribute('aria-label')).toBe('Input');
    await fillIn('textarea', 'Hello');
    expect(seen).toEqual([]);
    for (let i = 0; i < 100 && seen.length !== 1; i++) await wait(20);
    expect(seen).toEqual(['Hello']);
    await click('.canon-button:last-child');
    expect(seen).toEqual(['Hello', '']);
    expect(find<HTMLButtonElement>('.canon-button:last-child').disabled).toBe(
      true,
    );
  });
});
