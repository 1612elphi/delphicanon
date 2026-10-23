import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
	click,
	fillIn,
	render,
	triggerEvent,
	triggerKeyEvent,
} from '@ember/test-helpers';
import CanonCommand, {
	type CanonCommandItem,
} from '#src/components/canon-command.gts';
import Dot from '../helpers/dot.gts';

const items: CanonCommandItem[] = [
	{
		id: 'contrast',
		title: 'Contrast checker',
		group: 'Colour',
		icon: Dot,
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
	const id = document
		.querySelector('.canon-command-input')!
		.getAttribute('aria-activedescendant');
	return id
		? document
				.getElementById(id)!
				.querySelector('.canon-command-title')!
				.textContent
		: null;
};

module('Component | canon-command', function (hooks) {
	setupRenderingTest(hooks);

	test('a combobox over grouped options, filtered and ranked', async function (assert) {
		const queries: string[] = [];
		const query = (text: string) => queries.push(text);
		await render(
			<template>
				<CanonCommand
					@items={{items}}
					@placeholder="Search tools"
					@onQuery={{query}}
				/>
			</template>,
		);
		assert.dom('.canon-command-input')
			.hasAttribute('role', 'combobox')
			.hasAttribute('aria-expanded', 'true')
			.hasAttribute(
				'aria-controls',
				document.querySelector('[role=listbox]')!.id,
			);
		assert.dom('[role=group]').exists({ count: 2 });
		assert.dom('[role=option]').exists({ count: 5 });
		assert.dom('.canon-heading').hasText('Colour');
		assert.dom('.canon-command-icon svg').exists({ count: 1 });
		assert.dom('.canon-command-key').exists({ count: 2 });
		assert.dom('[aria-disabled=true]').hasText('Paste');
		assert.strictEqual(activeTitle(), 'Contrast checker');

		await fillIn('.canon-command-input', 'len');
		assert.deepEqual(queries, ['len']);
		assert.dom('[role=option]').exists(
			{ count: 1 },
			'a keyword matches',
		);
		assert.strictEqual(activeTitle(), 'Word counter');

		await fillIn('.canon-command-input', 'zzz');
		assert.dom('[role=option]').doesNotExist();
		assert.dom('.canon-command-empty').hasText('No results');
		assert.dom('.canon-command-input').doesNotHaveAttribute(
			'aria-activedescendant',
		);
	});

	test('the arrow keys wrap past disabled rows; Enter and a click select', async function (assert) {
		const picked: string[] = [];
		const select = (item: CanonCommandItem) => picked.push(item.id);
		await render(
			<template>
				<CanonCommand
					@items={{items}}
					@onSelect={{select}}
				/>
			</template>,
		);
		const input = '.canon-command-input';
		await triggerKeyEvent(input, 'keydown', 'ArrowUp');
		assert.strictEqual(
			activeTitle(),
			'Copy',
			'wraps to the last row',
		);
		await triggerKeyEvent(input, 'keydown', 'ArrowUp');
		assert.strictEqual(
			activeTitle(),
			'Word counter',
			'skips Paste',
		);
		await triggerKeyEvent(input, 'keydown', 'Enter');
		assert.deepEqual(picked, ['count']);

		await triggerEvent(
			'[role=option]:nth-of-type(2)',
			'pointermove',
		);
		assert.strictEqual(
			activeTitle(),
			'Tailwind shades',
			'the pointer moves it',
		);
		await click('[aria-disabled=true]');
		assert.deepEqual(
			picked,
			['count'],
			'a disabled row does nothing',
		);
		await click('[role=option]');
		assert.deepEqual(picked, ['count', 'contrast']);

		await fillIn(input, 'cop');
		await triggerKeyEvent(input, 'keydown', 'Escape');
		assert.dom(input).hasValue('', 'Escape clears the query');
		assert.dom('[role=option]').exists({ count: 5 });
	});
});
