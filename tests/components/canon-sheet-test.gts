import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { render, settled, waitUntil } from '@ember/test-helpers';
import CanonSheet, {
	type CanonSheetEdge,
} from '#src/components/canon-sheet.gts';

class State {
	@tracked open = true;
	@tracked edge: CanonSheetEdge = 'end';
	close = () => (this.open = false);
}

module('Component | canon-sheet', function (hooks) {
	setupRenderingTest(hooks);

	test('a modal dialog on an edge of the window', async function (assert) {
		const state = new State();
		await render(
			<template>
				<CanonSheet
					@open={{state.open}}
					@edge={{state.edge}}
					@title="Sheet"
					@onClose={{state.close}}
				>
					<p>Body</p>
				</CanonSheet>
			</template>,
		);
		const sheet = document.querySelector('dialog')!;
		assert.true(sheet.matches(':modal'));
		assert.dom(sheet)
			.hasClass('canon-dialog')
			.hasClass('canon-sheet--end');
		await waitUntil(() => sheet.getAnimations().length === 0);
		const box = sheet.getBoundingClientRect();
		assert.strictEqual(
			Math.round(box.right),
			document.documentElement.clientWidth,
			'meets the end edge',
		);
		assert.strictEqual(Math.round(box.height), window.innerHeight);

		sheet.dispatchEvent(new Event('cancel', { cancelable: true }));
		await waitUntil(() => !sheet.open);
		await settled();
		assert.false(state.open, 'Escape closes it');

		state.edge = 'bottom';
		state.open = true;
		await settled();
		assert.dom(sheet).hasClass('canon-sheet--bottom');
		await waitUntil(() => sheet.getAnimations().length === 0);
		assert.strictEqual(
			Math.round(sheet.getBoundingClientRect().bottom),
			window.innerHeight,
			'meets the bottom edge',
		);
	});

	test('keeps its edge and height when the dialog sheet loads later', async function (assert) {
		const later = document.createElement('style');
		later.textContent = [...document.styleSheets]
			.flatMap((sheet) => [...sheet.cssRules])
			.filter(
				(rule) =>
					rule instanceof CSSStyleRule &&
					rule.selectorText === '.canon-dialog',
			)
			.map((rule) => rule.cssText)
			.join('\n');
		document.head.append(later);
		try {
			await render(
				<template>
					<CanonSheet
						@open={{true}}
						@edge="end"
						@title="Sheet"
					>
						<p>Body</p>
					</CanonSheet>
				</template>,
			);
			assert.notStrictEqual(
				later.textContent,
				'',
				'the dialog rule exists',
			);
			const sheet = document.querySelector('dialog')!;
			await waitUntil(
				() => sheet.getAnimations().length === 0,
			);
			const box = sheet.getBoundingClientRect();
			assert.strictEqual(
				Math.round(box.top),
				0,
				'meets the top edge',
			);
			assert.strictEqual(
				Math.round(box.height),
				window.innerHeight,
			);
		} finally {
			later.remove();
		}
	});
});
