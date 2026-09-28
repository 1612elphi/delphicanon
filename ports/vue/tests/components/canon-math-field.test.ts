import { expect, test } from 'vitest';
import CanonMathField, {
  CanonMathFieldHandle,
} from '../../src/components/canon-math-field.vue';
import {
  click,
  find,
  render,
  settled,
  triggerKeyEvent,
  waitUntil,
} from '../helpers/render.ts';

// the sheet closes after its 350 ms slide
const closed = () => waitUntil(() => !document.querySelector('dialog'));

test('the field opens the keypad sheet and reports edits', async () => {
  const changes: string[] = [];
  let completed: string | undefined;
  const change = (text: string) => changes.push(text);
  const complete = (text: string) => (completed = text);
  const handle = new CanonMathFieldHandle();
  await render(
    `<CanonMathField
      text="x"
      placeholder="y"
      :on-change="change"
      :on-completion="complete"
      :handle="handle"
    />`,
    { CanonMathField, change, complete, handle },
  );
  expect(document.querySelector('dialog')).toBeNull();
  await click('.canon-math-field');
  expect(document.querySelector('dialog.canon-math-input')).not.toBeNull();
  expect(find<HTMLDialogElement>('dialog').open).toBe(true);
  await click('dialog [aria-label="2"]');
  await triggerKeyEvent('dialog', 'keydown', '+');
  await triggerKeyEvent('dialog', 'keydown', '1');
  expect(changes).toEqual(['x*2', 'x*2+', 'x*2+1']);
  await click('dialog [aria-label="Done"]');
  await closed();
  await settled();
  expect(completed, 'completed').toBe('x*2+1');
  expect(document.querySelector('dialog')).toBeNull();
  expect(
    find('.canon-math-field .canon-math-view'),
    'field label',
  ).toHaveAttribute('aria-label', 'x*2+1');

  handle.edit([{ kind: 'fraction' }]);
  await settled();
  expect(
    document.querySelector('dialog'),
    'an insert key opens the sheet',
  ).not.toBeNull();
  expect(changes.at(-1), 'and types itself').toBe('x*2+1*()/()');
  find('dialog').dispatchEvent(new Event('cancel', { cancelable: true }));
  await closed();
  await settled();
  expect(document.querySelector('dialog'), 'Escape closes it').toBeNull();
  expect(completed).toBe('x*2+1*()/()');
});
