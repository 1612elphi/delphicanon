import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonImageCompare from '../src/components/canon-image-compare.svelte';
import Sized from './fixtures/canon-image-compare-sized.svelte';
import { find, triggerKeyEvent } from './helpers.ts';

const pixel =
  'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="2" height="1"/%3E';

describe('canon-image-compare', () => {
  test('a slider with titles; keys move the divider', async () => {
    await render(Sized, { picture: pixel });
    const slider = () => find('[role=slider]');
    expect(slider().getAttribute('aria-valuenow')).toBe('50');
    expect(slider().getAttribute('aria-label')).toBe('Before, Grey');
    expect(find('.canon-image-compare-tag--after').textContent).toBe('Grey');
    await triggerKeyEvent('[role=slider]', 'keydown', 'ArrowRight');
    expect(slider().getAttribute('aria-valuenow')).toBe('60');
    await triggerKeyEvent('[role=slider]', 'keydown', 'Home');
    expect(slider().getAttribute('aria-valuetext')).toBe('0%');
  });

  test('a failure dims the original and hides the divider', async () => {
    await render(CanonImageCompare, {
      before: pixel,
      failed: true,
      failure: 'No',
    });
    expect(document.querySelector('[role=slider]')).toBeNull();
    expect(document.querySelector('.canon-image-compare-divider')).toBeNull();
    expect(find('.canon-image-compare-failure').textContent).toBe('No');
  });
});
