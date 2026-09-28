import { describe, expect, test } from 'vitest';
import CanonMathView from '../../src/components/canon-math-view.tsx';
import { findAll, render, wait } from '../helpers/render.tsx';

describe('canon-math-view', () => {
  test('the view sets text as maths and scales down to fit', async () => {
    await render(
      <>
        <div style={{ width: 40 }}>
          <CanonMathView text="x^2 + 1/2" />
        </div>
        <CanonMathView className="faint" text="y" faint />
        <CanonMathView className="shown" text="b*c^(-1)" presents />
      </>,
    );
    const svg = document.querySelector<SVGSVGElement>('svg.canon-math-view')!;
    expect(svg.getAttribute('aria-label')).toBe('x^2 + 1/2');
    expect([...svg.querySelectorAll('text')].map((t) => t.textContent)).toEqual(
      ['x', '2', '+', '1', '2'],
    );
    expect(svg.querySelectorAll('rect').length).toBe(1);
    expect(svg.getBoundingClientRect().width).toBeLessThanOrEqual(40.5);
    expect(document.querySelector('.faint')!.classList).toContain(
      'canon-math-view--faint',
    );
    expect(findAll('.shown text').map((t) => t.textContent)).toEqual([
      'b',
      'c',
    ]);
  });

  test('a morphing view animates the glyphs that stay', async () => {
    const view = (text: string) => (
      <div style={{ width: 300, height: 80 }}>
        <CanonMathView text={text} morphs style={{ height: 80 }} />
      </div>
    );
    const { rerender } = await render(view('x+1'));
    expect(findAll('.canon-math-view g text').length).toBe(3);
    await rerender(view('x+2'));
    const glyphs = findAll('.canon-math-view g text');
    const moving = glyphs.filter((g) => g.getAnimations().length > 0);
    expect(moving.length).toBeGreaterThanOrEqual(3);
    expect(glyphs.some((g) => g.textContent === '1')).toBe(true);
    await wait(650);
    expect(
      findAll('.canon-math-view g text').map((g) => g.textContent),
    ).toEqual(['x', '+', '2']);
  });
});
