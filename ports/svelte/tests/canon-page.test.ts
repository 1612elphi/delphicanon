import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Scenes from './fixtures/canon-layout-scenes.svelte';
import { find } from './helpers.ts';

describe('canon-page', () => {
	test('caps and centres sections; a canvas spans the width', async () => {
		await render(Scenes, { scene: 'page' });
		const section = find('.section');
		expect(section.offsetWidth).toBe(720);
		expect(section.offsetLeft).toBe(140);
		expect(find('.canon-canvas').offsetWidth).toBe(1000);
	});

	test('null maxWidth leaves only the padding', async () => {
		await render(Scenes, { scene: 'page-uncapped' });
		expect(find('.section').offsetWidth).toBe(968);
	});
});
