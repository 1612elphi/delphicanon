import { describe, expect, test } from 'vitest';
import CanonSidebarRow from '../../src/components/canon-sidebar-row.tsx';
import Dot from '../helpers/dot.tsx';
import { click, find, findAll, render } from '../helpers/render.tsx';

describe('canon-sidebar-row', () => {
	test('is a button that reports clicks', async () => {
		let clicks = 0;
		await render(
			<CanonSidebarRow
				title="Toolbox"
				icon={<Dot />}
				onClick={() => clicks++}
			/>,
		);
		expect(find('button.canon-sidebar-row').textContent).toBe(
			'Toolbox',
		);
		const row = find('.canon-sidebar-row');
		expect(row.hasAttribute('aria-current')).toBe(false);
		expect(
			row.classList.contains('canon-sidebar-row--neutral'),
		).toBe(true);
		expect(findAll('.canon-sidebar-row-icon svg')).toHaveLength(1);
		await click(row);
		expect(clicks).toBe(1);
	});

	test('is a link with an href and marks the current page', async () => {
		await render(
			<CanonSidebarRow
				title="General"
				href="#general"
				light="warning"
				selected
			/>,
		);
		expect(find('a.canon-sidebar-row').getAttribute('href')).toBe(
			'#general',
		);
		const row = find('.canon-sidebar-row');
		expect(row.getAttribute('aria-current')).toBe('page');
		expect(
			row.classList.contains('canon-sidebar-row--warning'),
		).toBe(true);
	});

	test('lights the leading edge only when on or warning', async () => {
		await render(
			<>
				<CanonSidebarRow
					className="on"
					title="A"
					light="on"
				/>
				<CanonSidebarRow
					className="off"
					title="B"
					light="off"
				/>
			</>,
		);
		const capsule = (selector: string) =>
			getComputedStyle(find(selector), '::after').content;
		expect(capsule('.on')).toBe('""');
		expect(capsule('.off')).toBe('none');
	});
});
