import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import {
  click,
  focus,
  render,
  settled,
  triggerEvent,
  waitUntil,
} from '@ember/test-helpers';
import CanonButton from '#src/components/canon-button.gts';
import CanonDialog from '#src/components/canon-dialog.gts';
import { css } from '../helpers/css.ts';

class State {
  @tracked open = false;
  closes: string[] = [];
  close = (value: string) => {
    this.open = false;
    this.closes.push(value);
  };
}

// waiters miss the motion
const closed = () =>
  waitUntil(() => !document.querySelector('dialog')!.open).then(settled);

const cancel = () =>
  document
    .querySelector('dialog')!
    .dispatchEvent(new Event('cancel', { cancelable: true }));

module('Component | canon-dialog', function (hooks) {
  setupRenderingTest(hooks);

  test('opens modal, returns a value from the footer and focus to the invoker', async function (assert) {
    const state = new State();
    const show = () => (state.open = true);
    await render(
      <template>
        <CanonButton id="opener" @text="Open" @onClick={{show}} />
        <CanonDialog
          @open={{state.open}}
          @title="Export"
          @message="Text"
          @onClose={{state.close}}
        >
          <:default>
            <p class="row">Body</p>
          </:default>
          <:footer as |close|>
            <CanonButton @text="Cancel" @onClick={{fn close "cancel"}} />
            <CanonButton @text="Save" @onClick={{fn close "save"}} />
          </:footer>
        </CanonDialog>
      </template>,
    );
    const dialog = document.querySelector('dialog')!;
    assert.false(dialog.open);
    assert.dom('.canon-dialog-body').doesNotExist('content renders while open');

    await focus('#opener');
    await click('#opener');
    assert.true(dialog.open);
    assert.true(dialog.matches(':modal'), 'showModal');
    assert
      .dom(dialog)
      .hasAttribute(
        'aria-labelledby',
        document.querySelector('.canon-heading')!.id,
      )
      .hasAttribute(
        'aria-describedby',
        document.querySelector('.canon-dialog-message')!.id,
      );
    assert.dom('.canon-dialog-title').hasText('Export');
    assert
      .dom('.canon-dialog-footer.canon-grid .canon-button')
      .exists({ count: 2 });

    await click('.canon-dialog-footer .canon-button:last-child');
    await closed();
    assert.deepEqual(state.closes, ['save']);
    assert.dom('#opener').isFocused('focus returns');
    assert.dom('.canon-dialog-body').doesNotExist();

    await click('#opener');
    cancel();
    await closed();
    assert.deepEqual(state.closes, ['save', ''], 'Escape closes with no value');
  });

  test('the backdrop closes a dialog but not an alert; dismissable false holds both', async function (assert) {
    const state = new State();
    const alert = new State();
    const held = new State();
    await render(
      <template>
        <CanonDialog @open={{state.open}} @onClose={{state.close}}>
          <p>Plain</p>
        </CanonDialog>
        <CanonDialog
          @open={{alert.open}}
          @alert={{true}}
          @onClose={{alert.close}}
        >
          <p>Alert</p>
        </CanonDialog>
        <CanonDialog
          @open={{held.open}}
          @dismissable={{false}}
          @onClose={{held.close}}
        >
          <p>Held</p>
        </CanonDialog>
      </template>,
    );
    const [plain, alerting, holding] = document.querySelectorAll('dialog');
    const backdrop = async (dialog: HTMLDialogElement) => {
      await triggerEvent(dialog, 'pointerdown');
      await triggerEvent(dialog, 'click', { clientX: 1, clientY: 1 });
    };

    state.open = true;
    await settled();
    await backdrop(plain!);
    await closed();
    assert.deepEqual(state.closes, [''], 'a plain dialog closes');

    alert.open = true;
    await settled();
    assert.dom(alerting).hasAttribute('role', 'alertdialog');
    await backdrop(alerting!);
    assert.true(alerting!.open, 'an alert stays');
    alerting!.dispatchEvent(new Event('cancel', { cancelable: true }));
    await waitUntil(() => !alerting!.open);
    await settled();
    assert.deepEqual(alert.closes, [''], 'Escape closes an alert');

    held.open = true;
    await settled();
    await backdrop(holding!);
    holding!.dispatchEvent(new Event('cancel', { cancelable: true }));
    await new Promise((resolve) => setTimeout(resolve, 300));
    assert.true(holding!.open, 'not dismissable');
    held.open = false;
    await settled();
    assert.false(holding!.open, 'the owner closes it');
  });

  test('the top layer covers fixed page elements at any z-index', async function (assert) {
    const state = new State();
    state.open = true;
    const floating = css(
      'position: fixed; inset: auto 0 0; block-size: 60px; z-index: 2147483647',
    );
    await render(
      <template>
        <div class="floating" style={{floating}}>Footer</div>
        <CanonDialog @open={{state.open}} @onClose={{state.close}}>
          <p>Body</p>
        </CanonDialog>
      </template>,
    );
    const box = document.querySelector('.floating')!.getBoundingClientRect();
    const hit = document.elementFromPoint(
      box.left + box.width / 2,
      box.top + box.height / 2,
    );
    assert.strictEqual(hit, document.querySelector('dialog'));
  });
});
