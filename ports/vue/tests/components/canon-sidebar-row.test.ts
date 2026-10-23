import { expect, test } from 'vitest';
import CanonSidebarRow from '../../src/components/canon-sidebar-row.vue';
import Dot from '../helpers/dot.ts';
import { click, find, render } from '../helpers/render.ts';

test('is a button that reports clicks', async () => {
	let clicks = 0;
	const tap = () => clicks++;
	await render(
		`<CanonSidebarRow title="Toolbox" :icon="Dot" :on-click="tap" />`,
		{ CanonSidebarRow, Dot, tap },
	);
	expect(find('button.canon-sidebar-row')).toHaveTextContent('Toolbox');
	expect(find('.canon-sidebar-row')).not.toHaveAttribute('aria-current');
	expect(find('.canon-sidebar-row')).toHaveClass(
		'canon-sidebar-row--neutral',
	);
	expect(find('.canon-sidebar-row-icon svg')).toBeInTheDocument();
	await click('.canon-sidebar-row');
	expect(clicks).toBe(1);
});

test('is a link with an href and marks the current page', async () => {
	await render(
		`<CanonSidebarRow
      title="General"
      href="#general"
      light="warning"
      :selected="true"
    />`,
		{ CanonSidebarRow },
	);
	expect(find('a.canon-sidebar-row')).toHaveAttribute('href', '#general');
	expect(find('.canon-sidebar-row')).toHaveAttribute(
		'aria-current',
		'page',
	);
	expect(find('.canon-sidebar-row')).toHaveClass(
		'canon-sidebar-row--warning',
	);
});

test('lights the leading edge only when on or warning', async () => {
	await render(
		`<CanonSidebarRow class="on" title="A" light="on" />
    <CanonSidebarRow class="off" title="B" light="off" />`,
		{ CanonSidebarRow },
	);
	const capsule = (selector: string) =>
		getComputedStyle(find(selector), '::after').content;
	expect(capsule('.on')).toBe('""');
	expect(capsule('.off')).toBe('none');
});
