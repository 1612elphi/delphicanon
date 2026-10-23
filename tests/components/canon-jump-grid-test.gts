import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { click, render, settled, waitUntil } from '@ember/test-helpers';
import CanonJumpGrid from '#src/components/canon-jump-grid.gts';

class State {
	@tracked open = true;
	picks: number[] = [];
	closes = 0;
	pick = (index: number) => this.picks.push(index);
	close = () => {
		this.open = false;
		this.closes += 1;
	};
}

const sections = [
	{ title: 'ISO A', detail: '16' },
	{ title: 'ISO B', detail: '11' },
	{ title: 'ISO C', detail: '9' },
	{ title: 'RA' },
];

const closed = () =>
	waitUntil(() => !document.querySelector('dialog')!.open).then(settled);

module('Component | canon-jump-grid', function (hooks) {
	setupRenderingTest(hooks);

	test('lights and focuses the current group, reports a pick after closing, closes on a click beside the tiles', async function (assert) {
		const state = new State();
		await render(
			<template>
				<CanonJumpGrid
					@open={{state.open}}
					@sections={{sections}}
					@current={{2}}
					@onPick={{state.pick}}
					@onClose={{state.close}}
				/>
			</template>,
		);
		const dialog = document.querySelector('dialog')!;
		assert.true(dialog.matches(':modal'));
		assert.dom(dialog).hasAttribute('aria-label', 'Sections');
		assert.dom('.canon-jump-grid-tile').exists({ count: 4 });
		assert.dom('.canon-jump-grid-tile--lit')
			.hasText('ISO C 9')
			.hasAttribute('aria-current', 'true')
			.isFocused();
		assert.dom(
			'.canon-jump-grid-tile:nth-child(4) .canon-jump-grid-detail',
		).doesNotExist();

		await click('.canon-jump-grid-tile:nth-child(2)');
		await closed();
		assert.deepEqual(state.picks, [1]);
		assert.strictEqual(state.closes, 1);

		state.open = true;
		await settled();
		await click('.canon-jump-grid-holder');
		await closed();
		assert.deepEqual(
			state.picks,
			[1],
			'a click beside the tiles picks nothing',
		);
		assert.strictEqual(state.closes, 2);
	});
});
