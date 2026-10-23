import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, settled, waitUntil } from '@ember/test-helpers';
import CanonJumpHeading from '#src/components/canon-jump-heading.gts';
import { css } from '../helpers/css.ts';

const groups = ['Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon'];
const box = css('block-size: 200px; overflow-y: auto');
const filler = css('block-size: 300px');

module('Component | canon-jump-heading', function (hooks) {
	setupRenderingTest(hooks);

	test('opens a grid of its scrolling box’s groups lit at the one in view; a pick scrolls there and focuses it', async function (assert) {
		await render(
			<template>
				<div class="list" style={{box}}>
					{{#each groups as |group|}}
						<CanonJumpHeading
							@text={{group}}
							@detail="3"
						/>
						<div style={{filler}}></div>
					{{/each}}
				</div>
			</template>,
		);
		const list = document.querySelector<HTMLElement>('.list')!;
		const headings = [
			...document.querySelectorAll<HTMLElement>(
				'.canon-jump-heading',
			),
		];
		assert.strictEqual(headings[0]!.tagName, 'H3', 'a heading');
		assert.dom('.canon-jump-heading-button')
			.exists({ count: 5 })
			.hasAttribute('aria-haspopup', 'dialog');

		list.scrollTop = headings[2]!.offsetTop - list.offsetTop;
		// the helper focuses first, which would scroll an off-screen heading in
		await click(headings[2]!.querySelector('button')!);
		assert.dom('.canon-jump-grid-tile').exists({ count: 5 });
		assert.dom('.canon-jump-grid-tile--lit').hasText('Gamma 3');

		await click('.canon-jump-grid-tile:nth-child(4)');
		const target = headings[3]!;
		await waitUntil(
			() =>
				!document.querySelector('dialog') &&
				Math.abs(
					target.getBoundingClientRect().top -
						list.getBoundingClientRect()
							.top,
				) < 2,
			{ timeout: 3000 },
		);
		await settled();
		assert.dom(target.querySelector('button')).isFocused();

		// the smooth scroll ends inside the 1 px litIndex allows
		await waitUntil(
			() =>
				Math.abs(
					target.getBoundingClientRect().top -
						list.getBoundingClientRect()
							.top,
				) < 0.5,
			{ timeout: 3000 },
		);
		await click(target.querySelector('button')!);
		assert.dom('.canon-jump-grid-tile--lit').hasText(
			'Delta 3',
			'a second open lights the group now in view',
		);
	});
});
