import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, rerender } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import CanonMathView from '#src/components/canon-math-view.gts';
import { css } from '../helpers/css.ts';

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
const all = (selector: string) => [
  ...document.querySelectorAll<HTMLElement>(selector),
];

module('Component | canon-math-view', function (hooks) {
  setupRenderingTest(hooks);

  test('the view sets text as maths and scales down to fit', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 40px"}}>
          <CanonMathView @text="x^2 + 1/2" />
        </div>
        <CanonMathView class="faint" @text="y" @faint={{true}} />
        <CanonMathView class="shown" @text="b*c^(-1)" @presents={{true}} />
      </template>,
    );
    const svg = document.querySelector<SVGSVGElement>('svg.canon-math-view')!;
    assert.dom(svg).hasAttribute('aria-label', 'x^2 + 1/2');
    assert.deepEqual(
      [...svg.querySelectorAll('text')].map((t) => t.textContent),
      ['x', '2', '+', '1', '2'],
    );
    assert.strictEqual(svg.querySelectorAll('rect').length, 1, 'fraction bar');
    assert.true(svg.getBoundingClientRect().width <= 40.5, 'fits 40 px');
    assert.dom('.faint').hasClass('canon-math-view--faint');
    assert.deepEqual(
      [...document.querySelectorAll('.shown text')].map((t) => t.textContent),
      ['b', 'c'],
      'b·c⁻¹ is presented as b over c',
    );
  });

  test('a morphing view animates the glyphs that stay', async function (assert) {
    class State {
      @tracked text = 'x+1';
    }
    const state = new State();
    await render(
      <template>
        <div style={{css "width: 300px; height: 80px"}}>
          <CanonMathView
            @text={{state.text}}
            @morphs={{true}}
            style={{css "height: 80px"}}
          />
        </div>
      </template>,
    );
    assert.strictEqual(all('.canon-math-view g text').length, 3);
    state.text = 'x+2';
    await rerender();
    const glyphs = all('.canon-math-view g text');
    const moving = glyphs.filter((g) => g.getAnimations().length > 0);
    assert.true(moving.length >= 3, 'the new glyphs and the staying ones move');
    assert.true(
      glyphs.some((g) => g.textContent === '1'),
      'the removed glyph stays while it fades',
    );
    await wait(650);
    assert.deepEqual(
      all('.canon-math-view g text').map((g) => g.textContent),
      ['x', '+', '2'],
    );
  });
});
