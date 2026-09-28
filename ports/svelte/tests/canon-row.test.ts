import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Scenes from './fixtures/canon-row-scenes.svelte';
import { find } from './helpers.ts';

describe('canon-row', () => {
  test('labels its control and passes the title id', async () => {
    await render(Scenes, { scene: 'labels' });
    expect(find('.canon-row').classList).toContain('canon-row--flush');
    expect(find('.canon-row-title').textContent).toBe('Mode');
    expect(find('.canon-row-detail').textContent).toBe('Caption');
    const id = find('.canon-row-title').id;
    expect(find('button').getAttribute('aria-labelledby')).toBe(id);
  });

  test('puts the control below the label when both do not fit', async () => {
    await render(Scenes, { scene: 'stacks' });
    const offset = (scope: string) =>
      find(`${scope} .canon-row-control`).offsetTop -
      find(`${scope} .canon-row-label`).offsetTop;
    expect(offset('.wide')).toBe(0);
    expect(offset('.narrow')).toBeGreaterThan(0);
  });

  test('a bar shrinks beside the title before the row stacks', async () => {
    await render(Scenes, { scene: 'bar' });
    const label = find('.canon-row-label');
    const bar = find('.canon-bar');
    expect(bar.getBoundingClientRect().top).toBeLessThan(
      label.getBoundingClientRect().bottom,
    );
    expect(bar.offsetWidth).toBeLessThan(160);
  });

  test('a sizing title stacks a row whose own title fits', async () => {
    await render(Scenes, { scene: 'sizing' });
    expect(find('.canon-row-control').offsetTop).toBeGreaterThan(
      find('.canon-row-label').offsetTop,
    );
  });
});
