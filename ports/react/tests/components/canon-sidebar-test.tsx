import { describe, expect, test } from 'vitest';
import CanonHeading from '../../src/components/canon-heading.tsx';
import CanonSidebar from '../../src/components/canon-sidebar.tsx';
import CanonSidebarRow from '../../src/components/canon-sidebar-row.tsx';
import { find, findAll, render } from '../helpers/render.tsx';

describe('canon-sidebar', () => {
	test('holds a hero, headings and rows', async () => {
		await render(
			<div style={{ height: 400 }}>
				<CanonSidebar
					aria-label="Main"
					hero={<img alt="" />}
				>
					<CanonHeading text="Modules" />
					<CanonSidebarRow title="Toolbox" />
					<CanonSidebarRow title="General" />
				</CanonSidebar>
			</div>,
		);
		expect(
			find('nav.canon-sidebar').getAttribute('aria-label'),
		).toBe('Main');
		expect(findAll('.canon-sidebar-hero img')).toHaveLength(1);
		expect(
			find(
				'.canon-sidebar-rows .canon-heading',
			).checkVisibility(),
		).toBe(true);
		expect(findAll('.canon-sidebar-row')).toHaveLength(2);
	});

	test('collapses to the icon rail', async () => {
		await render(
			<div style={{ display: 'flex', height: 400 }}>
				<CanonSidebar className="wide">
					<CanonHeading text="Modules" />
					<CanonSidebarRow title="Toolbox" />
				</CanonSidebar>
				<CanonSidebar className="rail" collapsed>
					<CanonHeading text="Modules" />
					<CanonSidebarRow title="Toolbox" />
				</CanonSidebar>
			</div>,
		);
		const wide = find('.wide');
		const rail = find('.rail');
		const cell = find('.rail .canon-sidebar-row-icon');
		expect(rail.offsetWidth).toBeLessThan(wide.offsetWidth / 4);
		expect(
			rail.offsetWidth,
			'the rail keeps the cell',
		).toBeGreaterThan(cell.offsetWidth);
		expect(find('.rail .canon-heading').checkVisibility()).toBe(
			false,
		);
		expect(
			find('.rail .canon-sidebar-row').textContent,
			'the title stays as the accessible name',
		).toBe('Toolbox');
	});

	test('compact rows are shorter and keep a square icon cell', async () => {
		await render(
			<div style={{ display: 'flex', height: 400 }}>
				<CanonSidebar className="regular">
					<CanonSidebarRow title="Toolbox" />
				</CanonSidebar>
				<CanonSidebar className="compact" compact>
					<CanonSidebarRow title="Toolbox" />
				</CanonSidebar>
			</div>,
		);
		const compact = find('.compact .canon-sidebar-row');
		expect(compact.offsetHeight).toBeLessThan(
			find('.regular .canon-sidebar-row').offsetHeight,
		);
		expect(
			find('.compact .canon-sidebar-row-icon').offsetWidth,
		).toBe(compact.offsetHeight);
	});
});
