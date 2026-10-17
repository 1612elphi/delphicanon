import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, rerender, triggerKeyEvent } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { array } from '@ember/helper';
import CanonPageStrip, {
  type CanonPage,
} from '#src/components/canon-page-strip.gts';
import { css } from '../helpers/css.ts';

class State {
  @tracked pages: CanonPage[] = [
    { size: { width: 595, height: 842 }, name: 'A' },
    { size: { width: 842, height: 595 }, name: 'B' },
    { size: { width: 595, height: 842 }, name: 'C', depth: 2 },
  ];
  @tracked selected = 1;
  moves: [number, number][] = [];
  move = (from: number, to: number) => {
    this.moves.push([from, to]);
    const pages = [...this.pages];
    pages.splice(to, 0, ...pages.splice(from, 1));
    this.pages = pages;
  };
  select = (index: number) => {
    this.selected = index;
  };
}

module('Component | canon-page-strip', function (hooks) {
  setupRenderingTest(hooks);

  test('pages to scale, lit, stacked, reordered by keyboard', async function (assert) {
    const state = new State();
    await render(
      <template>
        <div style={{css "width: 600px; height: 192px"}}>
          <CanonPageStrip
            @pages={{state.pages}}
            @selected={{state.selected}}
            @onSelect={{state.select}}
            @reorders={{true}}
            @onMove={{state.move}}
          />
        </div>
      </template>,
    );
    const papers = [
      ...document.querySelectorAll<HTMLElement>('.canon-page-strip-stack'),
    ];
    assert.strictEqual(papers.length, 3);
    const [portrait, landscape] = papers.map((p) => p.getBoundingClientRect());
    assert.true(portrait!.height > portrait!.width, 'portrait is tall');
    assert.true(landscape!.width > landscape!.height, 'landscape is wide');
    assert.dom('.canon-page-strip-cell--lit').hasText('2 B');
    assert.dom('.canon-page-strip-sheet').exists({ count: 2 });

    await click('[data-page-index="0"] .canon-page-strip-page');
    assert.strictEqual(state.selected, 0);
    assert
      .dom('[data-page-index="0"] button')
      .hasAttribute('aria-current', 'true');

    await triggerKeyEvent(
      '[data-page-index="0"] button',
      'keydown',
      'ArrowRight',
      { altKey: true },
    );
    await rerender();
    assert.deepEqual(state.moves, [[0, 1]]);
    assert.dom('[data-page-index="1"] .canon-page-strip-name').hasText('A');
  });

  test('no pages shows the empty text', async function (assert) {
    await render(<template><CanonPageStrip @pages={{(array)}} /></template>);
    assert.dom('.canon-page-strip-empty').hasText('Pages');
  });
  test('blank draws sheets with nothing to reach', async function (assert) {
    const landscape = [{ size: { width: 842, height: 595 } }];
    await render(
      <template>
        <div style={{css "width: 600px; height: 192px"}}>
          <CanonPageStrip @pages={{landscape}} @blank={{true}} />
        </div>
      </template>,
    );
    assert.dom('.canon-page-strip').hasAttribute('aria-hidden', 'true');
    assert.dom('.canon-page-strip-empty').doesNotExist();
    assert.dom('.canon-page-strip-number').doesNotExist();
    assert.dom('button, [tabindex]').doesNotExist();
    const sheets = document.querySelectorAll<HTMLElement>(
      '.canon-page-strip-paper',
    );
    assert.true(sheets.length > 1, 'sheets fill the strip');
    const last = sheets[sheets.length - 1]!.getBoundingClientRect();
    const strip = document
      .querySelector('.canon-page-strip')!
      .getBoundingClientRect();
    assert.true(last.left > strip.right, 'the last sheet runs past the edge');
    const first = sheets[0]!;
    assert.true(first.offsetWidth > first.offsetHeight, 'shaped as the page');
  });

  test('blank without pages draws A4 sheets', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 600px; height: 192px"}}>
          <CanonPageStrip @pages={{(array)}} @blank={{true}} />
        </div>
      </template>,
    );
    assert.dom('.canon-page-strip-empty').doesNotExist();
    const first = document.querySelector<HTMLElement>(
      '.canon-page-strip-paper',
    )!;
    assert.true(first.offsetHeight > first.offsetWidth);
  });
});
