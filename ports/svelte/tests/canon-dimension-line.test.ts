import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Scene from './fixtures/canon-dimension-line-scene.svelte';
import { find } from './helpers.ts';

describe('canon-dimension-line', () => {
  test('a rule with ticks and the figure, turned or blank', async () => {
    await render(Scene);
    expect(find('.across').getAttribute('aria-hidden')).toBe('true');
    expect(find('.across .canon-figure-said').textContent).toBe('1600px');
    expect(find('.across').offsetWidth).toBe(200);
    expect(find('.across').offsetHeight).toBe(32);
    expect(getComputedStyle(find('.down')).rotate).toBe('-90deg');
    expect(document.querySelector('.blank .canon-figure')).toBeNull();
    const ink = (selector: string) =>
      getComputedStyle(find(selector), '::before').backgroundColor;
    expect(ink('.blank'), 'blank ticks are muted').not.toBe(ink('.across'));
  });
});
