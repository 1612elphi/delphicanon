import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, rerender, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import CanonCanvas from '#src/components/canon-canvas.gts';
import { css } from '../helpers/css.ts';

class Fit {
  @tracked width = 400;
  @tracked shows = true;
}

module('Component | canon-canvas', function (hooks) {
  setupRenderingTest(hooks);

  test('sizes fixed, by aspect, and capped', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 400px"}}>
          <CanonCanvas class="fixed" @height={{120}}><span
            >Art</span></CanonCanvas>
          <CanonCanvas class="aspect" @aspect={{4}} />
          <CanonCanvas class="capped" @aspect={{4}} @maxHeight={{60}} />
        </div>
      </template>,
    );
    const height = (selector: string) =>
      document.querySelector<HTMLElement>(selector)!.offsetHeight;
    assert.strictEqual(height('.fixed'), 120);
    assert.strictEqual(
      height('.aspect'),
      104,
      'content 400 / 4 plus two rules',
    );
    assert.strictEqual(height('.capped'), 60);
    assert.dom('.fixed .canon-canvas-content').hasText('Art');
  });

  test('fitting takes its height from the content', async function (assert) {
    const fit = new Fit();
    await render(
      <template>
        <div style={{css (width fit.width)}}>
          <CanonCanvas class="fits" @fitting={{true}}>
            {{#if fit.shows}}
              <div style={{css "aspect-ratio: 2"}}></div>
            {{/if}}
          </CanonCanvas>
        </div>
      </template>,
    );
    const height = () =>
      document.querySelector<HTMLElement>('.fits')!.offsetHeight;
    await waitUntil(() => height() === 204);
    assert.strictEqual(height(), 204, 'half the width plus two rules');
    fit.width = 300;
    await rerender();
    await waitUntil(() => height() === 154);
    assert.strictEqual(height(), 154, 'refits on a width change');
    fit.shows = false;
    await rerender();
    await waitUntil(() => height() === 0);
    assert.strictEqual(height(), 0, 'no content, no band');
  });
});

function width(px: number) {
  return `width: ${px}px`;
}
