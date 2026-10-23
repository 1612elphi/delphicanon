import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Scenes from './fixtures/canon-window-scenes.svelte';
import { click, find, findAll } from './helpers.ts';

describe('canon-window', () => {
	test('draws the title bar and its controls', async () => {
		const calls: string[] = [];
		await render(Scenes, {
			scene: 'bar',
			onClose: () => calls.push('close'),
			onZoom: () => calls.push('zoom'),
		});
		expect(
			find('section.canon-window').getAttribute(
				'aria-labelledby',
			),
		).toMatch(/-title$/);
		expect(find('.canon-window-title').textContent).toBe('Delphi');
		expect(findAll('.canon-window-toolbar .tool')).toHaveLength(1);
		expect(findAll('.canon-window-menubar .menu')).toHaveLength(1);
		expect(findAll('.canon-window-main .detail')).toHaveLength(1);
		expect(
			find<HTMLButtonElement>('[aria-label="Minimise"]')
				.disabled,
		).toBe(true);
		await click('[aria-label="Close"]');
		await click('[aria-label="Zoom"]');
		expect(calls).toEqual(['close', 'zoom']);
	});

	test('leaves the controls out without callbacks', async () => {
		await render(Scenes, { scene: 'bare' });
		expect(findAll('.canon-window-controls')).toHaveLength(0);
		expect(findAll('.canon-window-menubar')).toHaveLength(0);
		expect(
			find('.canon-window').hasAttribute('aria-labelledby'),
		).toBe(false);
	});

	test('collapses its sidebar when narrow', async () => {
		await render(Scenes, { scene: 'widths' });
		const width = (selector: string) =>
			find(`${selector} .canon-sidebar`).offsetWidth;
		expect(width('.narrow')).toBeLessThan(width('.wide') / 4);
		expect(width('.kept')).toBe(width('.wide'));
	});
});
