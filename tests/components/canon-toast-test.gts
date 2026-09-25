import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled } from '@ember/test-helpers';
import CanonToast from '#src/components/canon-toast.gts';

module('Component | canon-toast', function (hooks) {
  setupRenderingTest(hooks);

  test('copy writes the text and shows it', async function (assert) {
    const toast = this.owner.lookup('service:canon-toast');
    const written: string[] = [];
    toast.write = (text) => {
      written.push(text);
      return Promise.resolve();
    };
    await render(<template><CanonToast /></template>);
    await toast.copy('#3B82F6');
    await settled();
    assert.deepEqual(written, ['#3B82F6']);
    assert.dom('.canon-toast-detail').hasText('#3B82F6');
    assert.dom('[role=status]').hasText('Copied');
    assert.strictEqual(
      document.querySelector<HTMLElement>('.canon-toast')!.style.opacity,
      '1',
    );
  });

  test('a failed write shows nothing', async function (assert) {
    const toast = this.owner.lookup('service:canon-toast');
    toast.write = () => Promise.reject(new Error('denied'));
    await render(<template><CanonToast /></template>);
    await toast.copy('x');
    await settled();
    assert.false(toast.visible);
    assert.dom('[role=status]').hasText('');
  });

  test('a long or multi-line value is left out', async function (assert) {
    const toast = this.owner.lookup('service:canon-toast');
    await render(<template><CanonToast /></template>);
    toast.show('one\ntwo');
    await settled();
    assert.dom('.canon-toast-detail').doesNotExist();
    assert.dom('.canon-toast-title').hasText('Copied');
  });
});
