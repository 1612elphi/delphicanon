import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Letters from './fixtures/canon-glyph-flow-letters.svelte';
import { find, findAll, settled, waitUntil } from './helpers.ts';

describe('canon-glyph-flow', () => {
  test('glyphs paint through the block, one row centred, wrapping when long', async () => {
    const { rerender } = await render(Letters, {
      glyphs: [...'ab'],
      label: 'ab',
    });
    await waitUntil(() => findAll('.g').length === 2);
    expect(find('.canon-glyph-flow').getAttribute('aria-label')).toBe('ab');
    const boxes = findAll('.canon-glyph-flow-glyph');
    const left = parseFloat(boxes[0]!.style.left);
    const right = parseFloat(boxes[1]!.style.left) + 28;
    // a single row is centred
    expect(left + right).toBe(300);

    await rerender({ glyphs: [...'abcdefghijklmnopqrstuvwxyz'] });
    await settled();
    const tops = new Set(
      findAll('.canon-glyph-flow-glyph').map((g) => g.style.top),
    );
    // wraps into rows
    expect(tops.size).toBeGreaterThan(1);
  });

  test('no glyphs shows the empty block', async () => {
    await render(Letters, { glyphs: [] });
    expect(document.querySelector('.nothing')).not.toBeNull();
  });
});
