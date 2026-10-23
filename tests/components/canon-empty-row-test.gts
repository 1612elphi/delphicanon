import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonEmptyRow from '#src/components/canon-empty-row.gts';

module('Component | canon-empty-row', function (hooks) {
	setupRenderingTest(hooks);

	test('shows its text in a tall row', async function (assert) {
		await render(
			<template>
				<CanonEmptyRow @text="Nothing here" />
			</template>,
		);
		assert.dom('.canon-empty-row').hasText('Nothing here');
		assert.strictEqual(
			document.querySelector<HTMLElement>('.canon-empty-row')!
				.offsetHeight,
			96,
		);
	});
});
