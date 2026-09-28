import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Scenes from './fixtures/canon-sidebar-scenes.svelte';
import { find, findAll } from './helpers.ts';

const visible = (element: HTMLElement) => element.checkVisibility();

describe('canon-sidebar', () => {
  test('holds a hero, headings and rows', async () => {
    await render(Scenes, { scene: 'parts' });
    expect(find('nav.canon-sidebar').getAttribute('aria-label')).toBe('Main');
    expect(findAll('.canon-sidebar-hero img')).toHaveLength(1);
    expect(visible(find('.canon-sidebar-rows .canon-heading'))).toBe(true);
    expect(findAll('.canon-sidebar-row')).toHaveLength(2);
  });

  test('collapses to the icon rail', async () => {
    await render(Scenes, { scene: 'rail' });
    const wide = find('.wide');
    const rail = find('.rail');
    const cell = find('.rail .canon-sidebar-row-icon');
    expect(rail.offsetWidth).toBeLessThan(wide.offsetWidth / 4);
    expect(rail.offsetWidth, 'the rail keeps the cell').toBeGreaterThan(
      cell.offsetWidth,
    );
    expect(visible(find('.rail .canon-heading'))).toBe(false);
    expect(
      find('.rail .canon-sidebar-row').textContent?.trim(),
      'the title stays as the accessible name',
    ).toBe('Toolbox');
  });
});
