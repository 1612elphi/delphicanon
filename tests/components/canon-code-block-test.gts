import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import CanonCodeBlock from '#src/components/canon-code-block.gts';
import { css } from '../helpers/css.ts';

const long = Array.from(
  { length: 40 },
  (_, i) => `line ${i} ${'lorem ipsum '.repeat(12)}`,
).join('\n');

module('Component | canon-code-block', function (hooks) {
  setupRenderingTest(hooks);

  test('lines do not wrap, maxHeight caps, copy writes the code', async function (assert) {
    const toast = this.owner.lookup('service:canon-toast');
    const written: string[] = [];
    toast.write = (text) => {
      written.push(text);
      return Promise.resolve();
    };
    await render(
      <template>
        <div style={{css "width: 300px"}}>
          <CanonCodeBlock @code={{long}} @language="css" @maxHeight={{160}} />
        </div>
      </template>,
    );
    const code = document.querySelector<HTMLElement>('.canon-code-block-code')!;
    assert.true(code.scrollWidth > code.clientWidth, 'scrolls sideways');
    assert.strictEqual(code.offsetHeight, 160);
    assert.dom('.canon-code-block-language').hasText('css');
    await click('.canon-code-block-copy');
    assert.deepEqual(written, [long]);
    assert.dom('.canon-code-block-copy--copied').exists();
  });

  test('without a language the copy button sits below', async function (assert) {
    await render(<template><CanonCodeBlock @code="x" /></template>);
    const bar = document.querySelector('.canon-code-block-bar')!;
    const code = document.querySelector('.canon-code-block-code')!;
    assert.true(
      bar.getBoundingClientRect().top >= code.getBoundingClientRect().bottom,
    );
  });
});
