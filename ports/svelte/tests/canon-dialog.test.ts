import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Scenes from './fixtures/canon-dialog-scenes.svelte';
import { DialogState } from './fixtures/dialog-state.svelte.ts';
import {
  click,
  find,
  findAll,
  focus,
  settled,
  triggerEvent,
  wait,
  waitUntil,
} from './helpers.ts';

// the motion out is no pending update
const closed = () =>
  waitUntil(() => !find<HTMLDialogElement>('dialog').open).then(settled);

const cancel = () =>
  find('dialog').dispatchEvent(new Event('cancel', { cancelable: true }));

describe('canon-dialog', () => {
  test('opens modal, returns a value from the footer and focus to the invoker', async () => {
    const state = new DialogState();
    await render(Scenes, { scene: 'footer', state });
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
    expect(dialog.getAttribute('aria-labelledby')).toBe(
      find('.canon-heading').id,
    );
    expect(dialog.getAttribute('aria-describedby')).toBe(
      find('.canon-dialog-message').id,
    );
    expect(find('.canon-dialog-title').textContent).toBe('Export');
    expect(
      findAll('.canon-dialog-footer.canon-grid .canon-button'),
    ).toHaveLength(2);

    await click('.canon-dialog-footer .canon-button:last-child');
    await closed();
    expect(state.closes).toEqual(['save']);
    expect(document.activeElement, 'focus returns').toBe(find('#opener'));
    expect(findAll('.canon-dialog-body')).toHaveLength(0);

    await click('#opener');
    cancel();
    await closed();
    expect(state.closes, 'Escape closes with no value').toEqual(['save', '']);
  });

  test('the backdrop closes a dialog but not an alert; dismissable false holds both', async () => {
    const state = new DialogState();
    const alert = new DialogState();
    const held = new DialogState();
    await render(Scenes, { scene: 'backdrop', state, alert, held });
    const [plain, alerting, holding] = findAll<HTMLDialogElement>('dialog');
    const backdrop = async (dialog: HTMLDialogElement) => {
      await triggerEvent(dialog, 'pointerdown');
      await triggerEvent(dialog, 'click', { clientX: 1, clientY: 1 });
    };

    state.open = true;
    await settled();
    await backdrop(plain!);
    await closed();
    expect(state.closes, 'a plain dialog closes').toEqual(['']);

    alert.open = true;
    await settled();
    expect(alerting!.getAttribute('role')).toBe('alertdialog');
    await backdrop(alerting!);
    expect(alerting!.open, 'an alert stays').toBe(true);
    alerting!.dispatchEvent(new Event('cancel', { cancelable: true }));
    await waitUntil(() => !alerting!.open);
    await settled();
    expect(alert.closes, 'Escape closes an alert').toEqual(['']);

    held.open = true;
    await settled();
    await backdrop(holding!);
    holding!.dispatchEvent(new Event('cancel', { cancelable: true }));
    await wait(300);
    expect(holding!.open, 'not dismissable').toBe(true);
    held.open = false;
    await settled();
    expect(holding!.open, 'the owner closes it').toBe(false);
  });

  test('the top layer covers fixed page elements at any z-index', async () => {
    const state = new DialogState();
    state.open = true;
    await render(Scenes, { scene: 'top', state });
    await settled();
    const box = find('.floating').getBoundingClientRect();
    const hit = document.elementFromPoint(
      box.left + box.width / 2,
      box.top + box.height / 2,
    );
    expect(hit).toBe(find('dialog'));
  });
});
