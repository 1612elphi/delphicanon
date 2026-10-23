import { expect, test } from 'vitest';
import CanonImageCompare from '../../src/components/canon-image-compare.vue';
import { find, render, triggerKeyEvent } from '../helpers/render.ts';

const pixel =
	'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="2" height="1"/%3E';

test('a slider with titles; keys move the divider', async () => {
	await render(
		`<div style="width: 400px; height: 200px">
      <CanonImageCompare :before="pixel" :after="pixel" after-title="Grey" />
    </div>`,
		{ CanonImageCompare, pixel },
	);
	expect(find('[role=slider]')).toHaveAttribute('aria-valuenow', '50');
	expect(find('[role=slider]')).toHaveAttribute(
		'aria-label',
		'Before, Grey',
	);
	expect(find('.canon-image-compare-tag--after').textContent.trim()).toBe(
		'Grey',
	);
	await triggerKeyEvent('[role=slider]', 'keydown', 'ArrowRight');
	expect(find('[role=slider]')).toHaveAttribute('aria-valuenow', '60');
	await triggerKeyEvent('[role=slider]', 'keydown', 'Home');
	expect(find('[role=slider]')).toHaveAttribute('aria-valuetext', '0%');
});

test('a failure dims the original and hides the divider', async () => {
	await render(
		`<CanonImageCompare :before="pixel" :failed="true" failure="No" />`,
		{ CanonImageCompare, pixel },
	);
	expect(document.querySelector('[role=slider]')).toBeNull();
	expect(
		document.querySelector('.canon-image-compare-divider'),
	).toBeNull();
	expect(find('.canon-image-compare-failure').textContent.trim()).toBe(
		'No',
	);
});
