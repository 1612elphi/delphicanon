import { reactive } from 'vue';
import { expect, test } from 'vitest';
import CanonFigure from '../../src/components/canon-figure.vue';
import { find, findAll, render, settled } from '../helpers/render.ts';

test('rolls the changed characters only', async () => {
	const model = reactive({ text: '200' });
	await render(
		`<CanonFigure :text="model.text" unit="px" :size="28" />`,
		{
			CanonFigure,
			model,
		},
	);
	expect(find('.canon-figure-said').textContent?.trim()).toBe('200px');
	expect(findAll('.canon-figure-char')).toHaveLength(3);
	expect(find('.canon-figure-unit').textContent?.trim()).toBe('px');
	model.text = '250';
	await settled();
	expect(find('.canon-figure-said').textContent?.trim()).toBe('250px');
	expect(find('.canon-figure-text')).toMatchTextContent(/^250/);
	const rolling = findAll('.canon-figure-char').map(
		(c) => c.getAnimations().length > 0,
	);
	const still = window.matchMedia(
		'(prefers-reduced-motion: reduce)',
	).matches;
	expect(rolling).toEqual(
		still ? [false, false, false] : [false, true, false],
	);
});

test('a halo draws an outline shadow', async () => {
	await render(`<CanonFigure text="1" halo="black" />`, { CanonFigure });
	expect(getComputedStyle(find('.canon-figure')).textShadow).toContain(
		'0px 3px 5px',
	);
});
