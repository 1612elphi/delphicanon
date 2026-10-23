import { describe, expect, test } from 'vitest';
import CanonCommand, {
	type CanonCommandItem,
} from '../../src/components/canon-command.tsx';
import Dot from '../helpers/dot.tsx';
import {
	click,
	fillIn,
	find,
	findAll,
	key,
	render,
	trigger,
} from '../helpers/render.tsx';

const items: CanonCommandItem[] = [
	{
		id: 'contrast',
		title: 'Contrast checker',
		group: 'Colour',
		icon: <Dot />,
	},
	{ id: 'shades', title: 'Tailwind shades', group: 'Colour' },
	{
		id: 'count',
		title: 'Word counter',
		group: 'Text',
		keywords: ['length'],
	},
	{ id: 'paste', title: 'Paste', group: 'Text', disabled: true },
	{ id: 'copy', title: 'Copy', group: 'Text', shortcut: ['⌘', 'C'] },
];

const activeTitle = () => {
	const id = find('.canon-command-input').getAttribute(
		'aria-activedescendant',
	);
	return id
		? document
				.getElementById(id)!
				.querySelector('.canon-command-title')!
				.textContent
		: null;
};

describe('canon-command', () => {
	test('a combobox over grouped options, filtered and ranked', async () => {
		const queries: string[] = [];
		await render(
			<CanonCommand
				items={items}
				placeholder="Search tools"
				onQuery={(text) => queries.push(text)}
			/>,
		);
		const input = find('.canon-command-input');
		expect(input.getAttribute('role')).toBe('combobox');
		expect(input.getAttribute('aria-expanded')).toBe('true');
		expect(input.getAttribute('aria-controls')).toBe(
			find('[role=listbox]').id,
		);
		expect(findAll('[role=group]')).toHaveLength(2);
		expect(findAll('[role=option]')).toHaveLength(5);
		expect(find('.canon-heading').textContent).toBe('Colour');
		expect(findAll('.canon-command-icon svg')).toHaveLength(1);
		expect(findAll('.canon-command-key')).toHaveLength(2);
		expect(find('[aria-disabled=true]').textContent).toBe('Paste');
		expect(activeTitle()).toBe('Contrast checker');

		await fillIn(input, 'len');
		expect(queries).toEqual(['len']);
		expect(
			findAll('[role=option]'),
			'a keyword matches',
		).toHaveLength(1);
		expect(activeTitle()).toBe('Word counter');

		await fillIn(input, 'zzz');
		expect(findAll('[role=option]')).toHaveLength(0);
		expect(find('.canon-command-empty').textContent).toBe(
			'No results',
		);
		expect(input.hasAttribute('aria-activedescendant')).toBe(false);
	});

	test('the arrow keys wrap past disabled rows; Enter and a click select', async () => {
		const picked: string[] = [];
		await render(
			<CanonCommand
				items={items}
				onSelect={(item) => picked.push(item.id)}
			/>,
		);
		const input = '.canon-command-input';
		await key(input, 'ArrowUp');
		expect(activeTitle(), 'wraps to the last row').toBe('Copy');
		await key(input, 'ArrowUp');
		expect(activeTitle(), 'skips Paste').toBe('Word counter');
		await key(input, 'Enter');
		expect(picked).toEqual(['count']);

		await trigger('[role=option]:nth-of-type(2)', 'pointermove');
		expect(activeTitle(), 'the pointer moves it').toBe(
			'Tailwind shades',
		);
		await click('[aria-disabled=true]');
		expect(picked, 'a disabled row does nothing').toEqual([
			'count',
		]);
		await click('[role=option]');
		expect(picked).toEqual(['count', 'contrast']);

		await fillIn(input, 'cop');
		await key(input, 'Escape');
		expect(
			find<HTMLInputElement>(input).value,
			'Escape clears the query',
		).toBe('');
		expect(findAll('[role=option]')).toHaveLength(5);
	});
});
