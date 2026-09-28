import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Scene from './fixtures/canon-tooltip-scene.svelte';
import { find, triggerEvent, triggerKeyEvent } from './helpers.ts';

describe('canon-tooltip', () => {
  test('describes its trigger and shows on hover', async () => {
    await render(Scene);
    const tip = find('[role=tooltip]');
    expect(find('.target').getAttribute('aria-describedby')).toBe(tip.id);
    expect(tip.textContent?.trim()).toBe('Copy');
    expect(tip.matches(':popover-open')).toBe(false);

    await triggerEvent('.target', 'pointerenter');
    expect(tip.matches(':popover-open')).toBe(true);
    await triggerKeyEvent(document.documentElement, 'keydown', 'Escape');
    expect(tip.matches(':popover-open'), 'Escape hides it').toBe(false);

    await triggerEvent('.target', 'pointerenter');
    await triggerEvent('.target', 'pointerdown');
    expect(tip.matches(':popover-open'), 'a press hides it').toBe(false);
  });
});
