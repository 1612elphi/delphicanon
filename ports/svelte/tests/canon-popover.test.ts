import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Scene from './fixtures/canon-popover-scene.svelte';
import { click, find, waitUntil } from './helpers.ts';

describe('canon-popover', () => {
  test('the trigger toggles the anchored panel and gets focus back', async () => {
    await render(Scene);
    const trigger = find<HTMLButtonElement>('.opener');
    const panel = find('.canon-popover');
    expect(trigger.popoverTargetElement).toBe(panel);
    expect(trigger.getAttribute('aria-expanded')).toBe('false');
    expect(trigger.getAttribute('aria-controls')).toBe(panel.id);
    expect(panel.style.getPropertyValue('position-anchor')).toBe(
      trigger.style.getPropertyValue('anchor-name'),
    );
    expect(panel.style.getPropertyValue('position-area')).toBe(
      'block-start span-inline-start',
    );

    await click(trigger);
    expect(panel.matches(':popover-open')).toBe(true);
    await waitUntil(() => trigger.getAttribute('aria-expanded') === 'true');

    find('.inside').focus();
    await click('.inside');
    expect(panel.matches(':popover-open')).toBe(false);
    await waitUntil(() => document.activeElement === trigger);
    expect(trigger.getAttribute('aria-expanded')).toBe('false');
  });
});
