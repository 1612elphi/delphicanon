import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonSidebarRow from '../src/components/canon-sidebar-row.svelte';
import Lights from './fixtures/canon-sidebar-row-lights.svelte';
import { click, dot, find, findAll } from './helpers.ts';

describe('canon-sidebar-row', () => {
	test('is a button that reports clicks', async () => {
		let clicks = 0;
		await render(CanonSidebarRow, {
			title: 'Toolbox',
			icon: dot,
			onClick: () => clicks++,
		});
		expect(
			find('button.canon-sidebar-row').textContent?.trim(),
		).toBe('Toolbox');
		expect(
			find('.canon-sidebar-row').hasAttribute('aria-current'),
		).toBe(false);
		expect(find('.canon-sidebar-row').classList).toContain(
			'canon-sidebar-row--neutral',
		);
		expect(findAll('.canon-sidebar-row-icon svg')).toHaveLength(1);
		await click('.canon-sidebar-row');
		expect(clicks).toBe(1);
	});

	test('is a link with an href and marks the current page', async () => {
		await render(CanonSidebarRow, {
			title: 'General',
			href: '#general',
			light: 'warning',
			selected: true,
		});
		expect(find('a.canon-sidebar-row').getAttribute('href')).toBe(
			'#general',
		);
		expect(
			find('.canon-sidebar-row').getAttribute('aria-current'),
		).toBe('page');
		expect(find('.canon-sidebar-row').classList).toContain(
			'canon-sidebar-row--warning',
		);
	});

	test('lights the leading edge only when on or warning', async () => {
		await render(Lights);
		const capsule = (selector: string) =>
			getComputedStyle(find(selector), '::after').content;
		expect(capsule('.on')).toBe('""');
		expect(capsule('.off')).toBe('none');
	});
});
