import { reactive } from 'vue';
import { expect, test } from 'vitest';
import CanonSheet, {
  type CanonSheetEdge,
} from '../../src/components/canon-sheet.vue';
import { find, render, settled, waitUntil } from '../helpers/render.ts';

test('a modal dialog on an edge of the window', async () => {
  const state = reactive({
    open: true,
    edge: 'end' as CanonSheetEdge,
    close: () => (state.open = false),
  });
  await render(
    `<CanonSheet :open="state.open" :edge="state.edge" title="Sheet" :on-close="state.close">
      <p>Body</p>
    </CanonSheet>`,
    { CanonSheet, state },
  );
  const sheet = find<HTMLDialogElement>('dialog');
  expect(sheet.matches(':modal')).toBe(true);
  expect(sheet).toHaveClass('canon-dialog', 'canon-sheet--end');
  await waitUntil(() => sheet.getAnimations().length === 0);
  const box = sheet.getBoundingClientRect();
  expect(Math.round(box.right), 'meets the end edge').toBe(
    document.documentElement.clientWidth,
  );
  expect(Math.round(box.height)).toBe(window.innerHeight);

  sheet.dispatchEvent(new Event('cancel', { cancelable: true }));
  await waitUntil(() => !sheet.open);
  await settled();
  expect(state.open, 'Escape closes it; dismissable left out').toBe(false);

  state.edge = 'bottom';
  state.open = true;
  await settled();
  expect(sheet).toHaveClass('canon-sheet--bottom');
  await waitUntil(() => sheet.getAnimations().length === 0);
  expect(
    Math.round(sheet.getBoundingClientRect().bottom),
    'meets the bottom edge',
  ).toBe(window.innerHeight);
});
