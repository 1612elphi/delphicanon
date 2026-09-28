import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Scenes from './fixtures/canon-grid-scenes.svelte';
import { find, findAll, nextFrame, settled } from './helpers.ts';

describe('canon-grid', () => {
  test('balances rows: four cells at three columns are two rows of two', async () => {
    await render(Scenes, { scene: 'four' });
    const cells = findAll('.canon-grid > div');
    expect(cells.map((c) => c.offsetTop > cells[0]!.offsetTop)).toEqual([
      false,
      false,
      true,
      true,
    ]);
    expect(cells[0]!.offsetWidth).toBe(cells[3]!.offsetWidth);
  });

  test('the last cell of a short row spans the rest', async () => {
    await render(Scenes, { scene: 'five' });
    const cells = findAll('.canon-grid > div');
    expect(cells[3]!.offsetWidth).toBe(cells[0]!.offsetWidth);
    expect(cells[4]!.offsetWidth).toBe(cells[1]!.offsetWidth * 2 + 1);
  });

  test('filling buttons drop their titles together when one does not fit', async () => {
    await render(Scenes, { scene: 'titles' });
    await nextFrame();
    await settled();
    expect(find('.narrow .canon-grid').hasAttribute('data-symbol-only')).toBe(
      true,
    );
    expect(find('.narrow .canon-button-title').checkVisibility()).toBe(false);
    expect(find('.narrow .canon-button').getAttribute('aria-label')).toBe(
      'Loop',
    );
    expect(find('.wide .canon-grid').hasAttribute('data-symbol-only')).toBe(
      false,
    );
  });
});
