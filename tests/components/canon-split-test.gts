import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonSplit from '#src/components/canon-split.gts';
import { css } from '../helpers/css.ts';

const layout = () =>
  getComputedStyle(document.querySelector('.canon-split-body')!)
    .getPropertyValue('--canon-split-layout')
    .trim();
const box = (selector: string) =>
  document.querySelector(selector)!.getBoundingClientRect();

module('Component | canon-split', function (hooks) {
  setupRenderingTest(hooks);

  test('wide: a 340 px sidebar beside the main pane, banner across both', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 1000px; height: 600px"}}>
          <CanonSplit>
            <:banner><CanonCanvas @height={{100}} /></:banner>
            <:sidebar><div class="side">Side</div></:sidebar>
            <:main><div class="main">Main</div></:main>
            <:footer><div class="strip">Strip</div></:footer>
          </CanonSplit>
        </div>
      </template>,
    );
    assert.strictEqual(layout(), 'wide');
    const sidebar = document.querySelector<HTMLElement>(
      '.canon-split-sidebar',
    )!;
    const main = document.querySelector<HTMLElement>('.canon-split-main')!;
    assert.strictEqual(sidebar.offsetWidth, 340);
    assert.strictEqual(main.offsetLeft, 341);
    assert.strictEqual(
      document.querySelector<HTMLElement>('.canon-split-banner')!.offsetWidth,
      1000,
    );
    assert.dom('.canon-split-main .canon-split-footer').hasText('Strip');
  });

  test('narrow or portrait: one column, sidebar first', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 500px; height: 800px"}}>
          <CanonSplit>
            <:sidebar><div class="side">Side</div></:sidebar>
            <:main><div class="main">Main</div></:main>
          </CanonSplit>
        </div>
      </template>,
    );
    assert.strictEqual(layout(), 'stacked');
    assert.true(box('.main').top > box('.side').top);
    assert.strictEqual(box('.main').left, box('.side').left);
  });

  test('mainLeadsStacked and halves', async function (assert) {
    await render(
      <template>
        <div class="stacked" style={{css "width: 500px; height: 800px"}}>
          <CanonSplit @mainLeadsStacked={{true}}>
            <:sidebar><div class="side">Side</div></:sidebar>
            <:main><div class="main">Main</div></:main>
          </CanonSplit>
        </div>
        <div class="halves" style={{css "width: 1001px; height: 600px"}}>
          <CanonSplit @halves={{true}}>
            <:sidebar><CanonCanvas @aspect={{1}} /></:sidebar>
            <:main><div>Main</div></:main>
          </CanonSplit>
        </div>
      </template>,
    );
    assert.true(box('.stacked .side').top > box('.stacked .main').top);
    const picture = document.querySelector<HTMLElement>(
      '.halves .canon-split-sidebar .canon-canvas',
    )!;
    assert.strictEqual(picture.offsetWidth, 500);
    assert.strictEqual(picture.offsetHeight, 600, 'the picture fills its pane');
  });

  test('footerHidden takes the footer away', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 1000px; height: 600px"}}>
          <CanonSplit @footerHidden={{true}}>
            <:main><div>Main</div></:main>
            <:footer><div>Strip</div></:footer>
          </CanonSplit>
        </div>
      </template>,
    );
    assert.dom('.canon-split-footer').doesNotExist();
  });
});
