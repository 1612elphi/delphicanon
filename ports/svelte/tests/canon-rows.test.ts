import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Scenes from './fixtures/canon-layout-scenes.svelte';
import { find } from './helpers.ts';

describe('canon-rows', () => {
  test('stacks rows a hairline apart, framed on request', async () => {
    await render(Scenes, { scene: 'rows' });
    const a = find('.a');
    const b = find('.b');
    expect(b.offsetTop - (a.offsetTop + a.offsetHeight)).toBe(1);
    expect(getComputedStyle(find('.canon-rows')).paddingTop).toBe('2px');
  });
});
