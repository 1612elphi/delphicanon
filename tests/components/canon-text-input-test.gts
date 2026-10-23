import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, render, waitUntil } from '@ember/test-helpers';
import CanonTextInput from '#src/components/canon-text-input.gts';

module('Component | canon-text-input', function (hooks) {
	setupRenderingTest(hooks);

	test('typing arrives after a pause, Clear at once', async function (assert) {
		const seen: string[] = [];
		const onChange = (text: string) => seen.push(text);
		await render(
			<template>
				<CanonTextInput
					@value="Hi"
					@onChange={{onChange}}
				/>
			</template>,
		);
		assert.dom('textarea').hasValue('Hi');
		assert.dom('textarea').hasAria('label', 'Input');
		await fillIn('textarea', 'Hello');
		assert.deepEqual(seen, [], 'nothing while typing');
		await waitUntil(() => seen.length === 1, { timeout: 2000 });
		assert.deepEqual(seen, ['Hello']);
		await click('.canon-button:last-child');
		assert.deepEqual(seen, ['Hello', '']);
		assert.dom('.canon-button:last-child').isDisabled();
	});
});
