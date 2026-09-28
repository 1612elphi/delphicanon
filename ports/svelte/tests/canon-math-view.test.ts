import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Fit from './fixtures/canon-math-view-fit.svelte';
import Morph from './fixtures/canon-math-view-morph.svelte';
import { find, findAll, settled, wait } from './helpers.ts';

describe('canon-math-view', () => {
  test('the view sets text as maths and scales down to fit', async () => {
    await render(Fit);
    const svg = find<SVGSVGElement>('svg.canon-math-view');
    expect(svg.getAttribute('aria-label')).toBe('x^2 + 1/2');
    expect([...svg.querySelectorAll('text')].map((t) => t.textContent)).toEqual(
      ['x', '2', '+', '1', '2'],
    );
    expect(svg.querySelectorAll('rect').length, 'fraction bar').toBe(1);
    expect(svg.getBoundingClientRect().width, 'fits 40 px').toBeLessThanOrEqual(
      40.5,
    );
    expect(find('.faint').classList).toContain('canon-math-view--faint');
    expect(
      findAll('.shown text').map((t) => t.textContent),
      'b·c⁻¹ is presented as b over c',
    ).toEqual(['b', 'c']);
  });

  test('a morphing view animates the glyphs that stay', async () => {
    const screen = await render(Morph, { text: 'x+1' });
    expect(findAll('.canon-math-view g text').length).toBe(3);
    await screen.rerender({ text: 'x+2' });
    await settled();
    const glyphs = findAll('.canon-math-view g text');
    const moving = glyphs.filter((g) => g.getAnimations().length > 0);
    expect(
      moving.length,
      'the new glyphs and the staying ones move',
    ).toBeGreaterThanOrEqual(3);
    expect(
      glyphs.some((g) => g.textContent === '1'),
      'the removed glyph stays while it fades',
    ).toBe(true);
    await wait(650);
    expect(
      findAll('.canon-math-view g text').map((g) => g.textContent),
    ).toEqual(['x', '+', '2']);
  });
});
