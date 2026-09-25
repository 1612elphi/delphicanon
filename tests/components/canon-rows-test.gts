import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonRows from '#src/components/canon-rows.gts';

module('Component | canon-rows', function (hooks) {
  setupRenderingTest(hooks);

  test('stacks rows a hairline apart, framed on request', async function (assert) {
    await render(
      <template>
        <CanonRows @framed={{true}}>
          <div class="a">A</div>
          <div class="b">B</div>
        </CanonRows>
      </template>,
    );
    const a = document.querySelector<HTMLElement>('.a')!;
    const b = document.querySelector<HTMLElement>('.b')!;
    assert.strictEqual(b.offsetTop - (a.offsetTop + a.offsetHeight), 1);
    assert.dom('.canon-rows').hasStyle({ paddingTop: '2px' });
  });
});
