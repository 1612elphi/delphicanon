import { expect, test } from 'vitest';
import { ref } from 'vue';
import CanonMathView from '../../src/components/canon-math-view.vue';
import { find, findAll, render, settled, wait } from '../helpers/render.ts';

test('the view sets text as maths and scales down to fit', async () => {
  await render(
    `<div style="width: 40px">
      <CanonMathView text="x^2 + 1/2" />
    </div>
    <CanonMathView class="faint" text="y" :faint="true" />
    <CanonMathView class="shown" text="b*c^(-1)" :presents="true" />`,
    { CanonMathView },
  );
  const svg = find<SVGSVGElement>('svg.canon-math-view');
  expect(svg).toHaveAttribute('aria-label', 'x^2 + 1/2');
  expect([...svg.querySelectorAll('text')].map((t) => t.textContent)).toEqual([
    'x',
    '2',
    '+',
    '1',
    '2',
  ]);
  expect(svg.querySelectorAll('rect').length, 'fraction bar').toBe(1);
  expect(svg.getBoundingClientRect().width <= 40.5, 'fits 40 px').toBe(true);
  expect(find('.faint')).toHaveClass('canon-math-view--faint');
  expect(
    findAll('.shown text').map((t) => t.textContent),
    'b·c⁻¹ is presented as b over c',
  ).toEqual(['b', 'c']);
});

test('a morphing view animates the glyphs that stay', async () => {
  const text = ref('x+1');
  await render(
    `<div style="width: 300px; height: 80px">
      <CanonMathView :text="text" :morphs="true" style="height: 80px" />
    </div>`,
    { CanonMathView, text },
  );
  expect(findAll('.canon-math-view g text').length).toBe(3);
  text.value = 'x+2';
  await settled();
  const glyphs = findAll('.canon-math-view g text');
  const moving = glyphs.filter((g) => g.getAnimations().length > 0);
  expect(moving.length >= 3, 'the new glyphs and the staying ones move').toBe(
    true,
  );
  expect(
    glyphs.some((g) => g.textContent === '1'),
    'the removed glyph stays while it fades',
  ).toBe(true);
  await wait(650);
  expect(findAll('.canon-math-view g text').map((g) => g.textContent)).toEqual([
    'x',
    '+',
    '2',
  ]);
});
