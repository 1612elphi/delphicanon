import { reactive } from 'vue';
import { expect, test } from 'vitest';
import CanonButton from '../../src/components/canon-button.vue';
import CanonDialog from '../../src/components/canon-dialog.vue';
import {
  click,
  find,
  findAll,
  focus,
  render,
  settled,
  triggerEvent,
  waitUntil,
  wait,
} from '../helpers/render.ts';

function state(open = false) {
  const s = reactive({
    open,
    closes: [] as string[],
    close: (value: string) => {
      s.open = false;
      s.closes.push(value);
    },
  });
  return s;
}

// waiters miss the motion
const closed = () =>
  waitUntil(() => !find<HTMLDialogElement>('dialog').open).then(settled);

const cancel = () =>
  find('dialog').dispatchEvent(new Event('cancel', { cancelable: true }));

test('opens modal, returns a value from the footer and focus to the invoker', async () => {
  const s = state();
  const show = () => (s.open = true);
  await render(
    `<CanonButton id="opener" text="Open" :on-click="show" />
    <CanonDialog :open="s.open" title="Export" message="Text" :on-close="s.close">
      <template #default>
        <p class="row">Body</p>
      </template>
      <template #footer="{ close }">
        <CanonButton text="Cancel" :on-click="() => close('cancel')" />
        <CanonButton text="Save" :on-click="() => close('save')" />
      </template>
    </CanonDialog>`,
    { CanonButton, CanonDialog, s, show },
  );
  const dialog = find<HTMLDialogElement>('dialog');
  expect(dialog.open).toBe(false);
  expect(
    findAll('.canon-dialog-body'),
    'content renders while open',
  ).toHaveLength(0);

  await focus('#opener');
  await click('#opener');
  expect(dialog.open).toBe(true);
  expect(dialog.matches(':modal'), 'showModal').toBe(true);
  expect(dialog).toHaveAttribute('aria-labelledby', find('.canon-heading').id);
  expect(dialog).toHaveAttribute(
    'aria-describedby',
    find('.canon-dialog-message').id,
  );
  expect(find('.canon-dialog-title')).toHaveTextContent('Export');
  expect(findAll('.canon-dialog-footer.canon-grid .canon-button')).toHaveLength(
    2,
  );

  await click('.canon-dialog-footer .canon-button:last-child');
  await closed();
  expect(s.closes).toEqual(['save']);
  expect(find('#opener'), 'focus returns').toHaveFocus();
  expect(findAll('.canon-dialog-body')).toHaveLength(0);

  await click('#opener');
  cancel();
  await closed();
  expect(s.closes, 'Escape closes with no value').toEqual(['save', '']);
});

test('the backdrop closes a dialog but not an alert; dismissable false holds both', async () => {
  const plainState = state();
  const alertState = state();
  const heldState = state();
  await render(
    `<CanonDialog :open="plainState.open" :on-close="plainState.close">
      <p>Plain</p>
    </CanonDialog>
    <CanonDialog :open="alertState.open" :alert="true" :on-close="alertState.close">
      <p>Alert</p>
    </CanonDialog>
    <CanonDialog :open="heldState.open" :dismissable="false" :on-close="heldState.close">
      <p>Held</p>
    </CanonDialog>`,
    { CanonDialog, plainState, alertState, heldState },
  );
  const [plain, alerting, holding] = findAll<HTMLDialogElement>('dialog');
  const backdrop = async (dialog: HTMLDialogElement) => {
    await triggerEvent(dialog, 'pointerdown');
    await triggerEvent(dialog, 'click', { clientX: 1, clientY: 1 });
  };

  plainState.open = true;
  await settled();
  await backdrop(plain!);
  await waitUntil(() => !plain!.open);
  await settled();
  expect(
    plainState.closes,
    'a plain dialog closes; dismissable left out',
  ).toEqual(['']);

  alertState.open = true;
  await settled();
  expect(alerting).toHaveAttribute('role', 'alertdialog');
  await backdrop(alerting!);
  expect(alerting!.open, 'an alert stays').toBe(true);
  alerting!.dispatchEvent(new Event('cancel', { cancelable: true }));
  await waitUntil(() => !alerting!.open);
  await settled();
  expect(alertState.closes, 'Escape closes an alert').toEqual(['']);

  heldState.open = true;
  await settled();
  await backdrop(holding!);
  holding!.dispatchEvent(new Event('cancel', { cancelable: true }));
  await wait(300);
  expect(holding!.open, 'not dismissable').toBe(true);
  heldState.open = false;
  await settled();
  expect(holding!.open, 'the owner closes it').toBe(false);
});

test('the top layer covers fixed page elements at any z-index', async () => {
  const s = state(true);
  await render(
    `<div
      class="floating"
      style="position: fixed; inset: auto 0 0; block-size: 60px; z-index: 2147483647"
    >Footer</div>
    <CanonDialog :open="s.open" :on-close="s.close">
      <p>Body</p>
    </CanonDialog>`,
    { CanonDialog, s },
  );
  const box = find('.floating').getBoundingClientRect();
  const hit = document.elementFromPoint(
    box.left + box.width / 2,
    box.top + box.height / 2,
  );
  expect(hit).toBe(find('dialog'));
});
