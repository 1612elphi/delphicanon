import { expect, test } from 'vitest';
import CanonTooltip from '../../src/components/canon-tooltip.vue';
import {
  find,
  render,
  triggerEvent,
  triggerKeyEvent,
} from '../helpers/render.ts';

test('describes its trigger and shows on hover', async () => {
  await render(
    `<CanonTooltip text="Copy" v-slot="{ trigger }">
      <button type="button" class="target" :ref="trigger">C</button>
    </CanonTooltip>`,
    { CanonTooltip },
  );
  const tip = find('[role=tooltip]');
  expect(find('.target')).toHaveAttribute('aria-describedby', tip.id);
  expect(tip).toHaveTextContent('Copy');
  expect(tip.matches(':popover-open')).toBe(false);

  await triggerEvent('.target', 'pointerenter');
  expect(tip.matches(':popover-open')).toBe(true);
  await triggerKeyEvent(document.body, 'keydown', 'Escape');
  expect(tip.matches(':popover-open'), 'Escape hides it').toBe(false);

  await triggerEvent('.target', 'pointerenter');
  await triggerEvent('.target', 'pointerdown');
  expect(tip.matches(':popover-open'), 'a press hides it').toBe(false);
});
