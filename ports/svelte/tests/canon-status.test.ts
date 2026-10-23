import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonStatus from '../src/components/canon-status.svelte';
import { find } from './helpers.ts';

test('tone sets the colour; row pads it', async () => {
	await render(CanonStatus, { class: 'ok', text: 'Granted', tone: 'ok' });
	await render(CanonStatus, {
		class: 'row',
		text: 'Stopped',
		tone: 'warn',
		row: true,
	});
	expect(find('.ok').textContent).toBe('Granted');
	expect(find('.ok').classList).toContain('canon-status--ok');
	expect(find('.row').classList).toContain('canon-status--row');
	const ok = getComputedStyle(find('.ok'));
	const warn = getComputedStyle(find('.row'));
	expect(ok.color).not.toBe(warn.color);
	expect(warn.paddingTop).toBe('10px');
});
