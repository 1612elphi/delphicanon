import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import CanonDualList from '#src/components/canon-dual-list.gts';

const hidden = [{ id: 'b', name: 'Beta', caption: 'two' }];
const shown = [
	{ id: 'a', name: 'Alpha' },
	{ id: 'c', name: 'Gamma' },
];

module('Component | canon-dual-list', function (hooks) {
	setupRenderingTest(hooks);

	test('one selection between two lists drives the actions', async function (assert) {
		const calls: string[] = [];
		const right = (id: string) => calls.push(`right ${id}`);
		const reorder = (id: string, delta: number) =>
			calls.push(`reorder ${id} ${delta}`);
		await render(
			<template>
				<CanonDualList
					@left={{hidden}}
					@right={{shown}}
					@leftTitle="Hidden"
					@rightTitle="Shown"
					@listHeight={{140}}
					@onMoveRight={{right}}
					@onReorder={{reorder}}
				/>
			</template>,
		);
		const button = (text: string) =>
			[
				...document.querySelectorAll(
					'.canon-grid button',
				),
			].find((b) => b.textContent?.trim() === text)!;
		assert.dom('.canon-dual-list-items').exists({ count: 2 });
		assert.strictEqual(
			document.querySelector<HTMLElement>(
				'.canon-dual-list-items',
			)!.offsetHeight,
			140,
		);
		assert.dom(button('Show')).isDisabled();

		await click('.canon-dual-list-item');
		assert.dom('.canon-dual-list-item').hasAttribute(
			'aria-pressed',
			'true',
		);
		assert.dom(button('Show')).isNotDisabled();
		assert.dom(button('Up')).isDisabled();
		await click(button('Show'));

		const gamma = document.querySelectorAll(
			'.canon-dual-list-item',
		)[2]!;
		await click(gamma);
		assert.dom(button('Up')).isNotDisabled();
		assert.dom(button('Down')).isDisabled();
		await click(button('Up'));
		assert.deepEqual(calls, ['right b', 'reorder c -1']);
	});
});
