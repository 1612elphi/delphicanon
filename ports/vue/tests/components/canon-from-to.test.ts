import { expect, test } from 'vitest';
import CanonFromTo from '../../src/components/canon-from-to.vue';
import { find, findAll, render, select } from '../helpers/render.ts';

const rates = ['23.976', '24', '25'];

test('two named menus with an arrow between', async () => {
	const tos: number[] = [];
	const record = (index: number) => tos.push(index);
	await render(
		`<CanonFromTo :items="rates" :from="0" :to="2" :on-to-change="record" />`,
		{ CanonFromTo, rates, record },
	);
	expect(findAll('select')).toHaveLength(2);
	expect(document.querySelector('.canon-from-to-arrow')).not.toBeNull();
	expect(find('.canon-menu-cell:first-child select')).toHaveAttribute(
		'aria-label',
		'From',
	);
	await select('.canon-menu-cell:last-child select', '1');
	expect(tos).toEqual([1]);
	const [from, to] = findAll('.canon-menu-cell');
	expect(from!.offsetWidth).toBe(to!.offsetWidth);
});
