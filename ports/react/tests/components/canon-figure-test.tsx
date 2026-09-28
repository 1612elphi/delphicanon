import { describe, expect, test } from 'vitest';
import CanonFigure from '../../src/components/canon-figure.tsx';
import { find, findAll, render } from '../helpers/render.tsx';

describe('canon-figure', () => {
  test('rolls the changed characters only', async () => {
    const figure = (text: string) => (
      <CanonFigure text={text} unit="px" size={28} />
    );
    const { rerender } = await render(figure('200'));
    expect(find('.canon-figure-said').textContent).toBe('200px');
    expect(findAll('.canon-figure-char')).toHaveLength(3);
    expect(find('.canon-figure-unit').textContent).toBe('px');
    await rerender(figure('250'));
    expect(find('.canon-figure-said').textContent).toBe('250px');
    expect(find('.canon-figure-text').textContent).toMatch(/^250/);
    const rolling = findAll('.canon-figure-char').map(
      (c) => c.getAnimations().length > 0,
    );
    const still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    expect(rolling).toEqual(
      still ? [false, false, false] : [false, true, false],
    );
  });

  test('a halo draws an outline shadow', async () => {
    await render(<CanonFigure text="1" halo="black" />);
    expect(getComputedStyle(find('.canon-figure')).textShadow).toContain(
      '0px 3px 5px',
    );
  });
});
