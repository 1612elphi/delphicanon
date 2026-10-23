import { expect, test } from 'vitest';
import CanonPopover from '../../src/components/canon-popover.vue';
import { click, find, render, waitUntil } from '../helpers/render.ts';

test('the trigger toggles the anchored panel and gets focus back', async () => {
	await render(
		`<CanonPopover role="dialog" aria-label="Panel" placement="top-end">
      <template #trigger="{ trigger }">
        <button type="button" class="opener" :ref="trigger">Open</button>
      </template>
      <template #content="{ close }">
        <button type="button" class="inside" @click="close">Close</button>
      </template>
    </CanonPopover>`,
		{ CanonPopover },
	);
	const trigger = find<HTMLButtonElement>('.opener');
	const panel = find('.canon-popover');
	expect(trigger.popoverTargetElement).toBe(panel);
	expect(trigger).toHaveAttribute('aria-expanded', 'false');
	expect(trigger).toHaveAttribute('aria-controls', panel.id);
	expect(panel.style.getPropertyValue('position-anchor')).toBe(
		trigger.style.getPropertyValue('anchor-name'),
	);
	expect(panel.style.getPropertyValue('position-area')).toBe(
		'block-start span-inline-start',
	);

	await click(trigger);
	expect(panel.matches(':popover-open')).toBe(true);
	await waitUntil(() => trigger.getAttribute('aria-expanded') === 'true');

	find('.inside').focus();
	await click('.inside');
	expect(panel.matches(':popover-open')).toBe(false);
	await waitUntil(() => document.activeElement === trigger);
	expect(trigger).toHaveAttribute('aria-expanded', 'false');
});
