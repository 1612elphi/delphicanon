import { describe, expect, test } from 'vitest';
import CanonStatus from '../../src/components/canon-status.tsx';
import { find, render } from '../helpers/render.tsx';

describe('canon-status', () => {
	test('tone sets the colour; row pads it', async () => {
		await render(
			<>
				<CanonStatus
					className="ok"
					text="Granted"
					tone="ok"
				/>
				<CanonStatus
					className="row"
					text="Stopped"
					tone="warn"
					row
				/>
			</>,
		);
		expect(find('.ok').textContent).toBe('Granted');
		expect(find('.ok').classList).toContain('canon-status--ok');
		expect(find('.row').classList).toContain('canon-status--row');
		const ok = getComputedStyle(find('.ok'));
		const warn = getComputedStyle(find('.row'));
		expect(ok.color).not.toBe(warn.color);
		expect(warn.paddingTop).toBe('10px');
	});
});
