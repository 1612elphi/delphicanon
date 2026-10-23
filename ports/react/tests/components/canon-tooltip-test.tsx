import { describe, expect, test } from 'vitest';
import CanonTooltip from '../../src/components/canon-tooltip.tsx';
import { find, key, render, trigger } from '../helpers/render.tsx';

describe('canon-tooltip', () => {
	test('describes its trigger and shows on hover', async () => {
		await render(
			<CanonTooltip text="Copy">
				{(tip) => (
					<button
						type="button"
						className="target"
						ref={tip.trigger}
					>
						C
					</button>
				)}
			</CanonTooltip>,
		);
		const tip = find('[role=tooltip]');
		expect(find('.target').getAttribute('aria-describedby')).toBe(
			tip.id,
		);
		expect(tip.textContent).toBe('Copy');
		expect(tip.matches(':popover-open')).toBe(false);

		await trigger('.target', 'pointerenter');
		expect(tip.matches(':popover-open')).toBe(true);
		await key(document.body, 'Escape');
		expect(tip.matches(':popover-open'), 'Escape hides it').toBe(
			false,
		);

		await trigger('.target', 'pointerenter');
		await trigger('.target', 'pointerdown');
		expect(tip.matches(':popover-open'), 'a press hides it').toBe(
			false,
		);
	});
});
