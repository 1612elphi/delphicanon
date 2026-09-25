import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonBar from '#src/components/canon-bar.gts';
import CanonRow from '#src/components/canon-row.gts';
import { css } from '../helpers/css.ts';

module('Component | canon-row', function (hooks) {
  setupRenderingTest(hooks);

  test('labels its control and yields the title id', async function (assert) {
    await render(
      <template>
        <CanonRow @title="Mode" @detail="Caption" @form="flush" as |titleId|>
          <button type="button" aria-labelledby={{titleId}}>Go</button>
        </CanonRow>
      </template>,
    );
    assert.dom('.canon-row').hasClass('canon-row--flush');
    assert.dom('.canon-row-title').hasText('Mode');
    assert.dom('.canon-row-detail').hasText('Caption');
    const id = document.querySelector('.canon-row-title')!.id;
    assert.dom('button').hasAttribute('aria-labelledby', id);
  });

  test('puts the control below the label when both do not fit', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 600px"}} class="wide">
          <CanonRow @title="Label" @form="flush">
            <div style={{css "width: 300px; height: 44px"}}></div>
          </CanonRow>
        </div>
        <div style={{css "width: 300px"}} class="narrow">
          <CanonRow @title="Label" @form="flush">
            <div style={{css "width: 300px; height: 44px"}}></div>
          </CanonRow>
        </div>
      </template>,
    );
    const offset = (scope: string) => {
      const label = document.querySelector<HTMLElement>(
        `${scope} .canon-row-label`,
      )!;
      const control = document.querySelector<HTMLElement>(
        `${scope} .canon-row-control`,
      )!;
      return control.offsetTop - label.offsetTop;
    };
    assert.strictEqual(offset('.wide'), 0, 'side by side');
    assert.true(offset('.narrow') > 0, 'stacked');
  });

  test('a bar shrinks beside the title before the row stacks', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 260px"}}>
          <CanonRow @title="Detail and icon">
            <CanonBar
              style={{css "inline-size: 100%; max-inline-size: 160px"}}
              @share={{0.5}}
            />
          </CanonRow>
        </div>
      </template>,
    );
    const label = document.querySelector<HTMLElement>('.canon-row-label')!;
    const bar = document.querySelector<HTMLElement>('.canon-bar')!;
    assert.true(
      bar.getBoundingClientRect().top < label.getBoundingClientRect().bottom,
      'beside the title',
    );
    assert.true(bar.offsetWidth < 160, 'shrunk');
  });

  test('a sizing title stacks a row whose own title fits', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 300px"}}>
          <CanonRow
            @title="A"
            @sizingTitle="A much longer title than this row has"
          >
            <div style={{css "width: 120px; height: 30px"}}></div>
          </CanonRow>
        </div>
      </template>,
    );
    const label = document.querySelector<HTMLElement>('.canon-row-label')!;
    const control = document.querySelector<HTMLElement>('.canon-row-control')!;
    assert.true(control.offsetTop > label.offsetTop);
  });
});
