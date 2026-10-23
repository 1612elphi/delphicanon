import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Scene from './fixtures/canon-sheet-scene.svelte';
import { DialogState } from './fixtures/dialog-state.svelte.ts';
import { find, settled, waitUntil } from './helpers.ts';

describe('canon-sheet', () => {
	test('a modal dialog on an edge of the window', async () => {
		const state = new DialogState();
		state.open = true;
		await render(Scene, { state });
		const sheet = find<HTMLDialogElement>('dialog');
		expect(sheet.matches(':modal')).toBe(true);
		expect(sheet.classList).toContain('canon-dialog');
		expect(sheet.classList).toContain('canon-sheet--end');
		await waitUntil(() => sheet.getAnimations().length === 0);
		const box = sheet.getBoundingClientRect();
		expect(Math.round(box.right), 'meets the end edge').toBe(
			document.documentElement.clientWidth,
		);
		expect(Math.round(box.height)).toBe(window.innerHeight);

		sheet.dispatchEvent(new Event('cancel', { cancelable: true }));
		await waitUntil(() => !sheet.open);
		await settled();
		expect(state.open, 'Escape closes it').toBe(false);

		state.edge = 'bottom';
		state.open = true;
		await settled();
		expect(sheet.classList).toContain('canon-sheet--bottom');
		await waitUntil(() => sheet.getAnimations().length === 0);
		expect(
			Math.round(sheet.getBoundingClientRect().bottom),
			'meets the bottom edge',
		).toBe(window.innerHeight);
	});
});
