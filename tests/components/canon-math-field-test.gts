import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
	click,
	render,
	settled,
	triggerKeyEvent,
	waitUntil,
} from '@ember/test-helpers';
import CanonMathField, {
	CanonMathFieldHandle,
} from '#src/components/canon-math-field.gts';

// the sheet closes after its 350 ms slide, which test waiters do not track
const closed = () => waitUntil(() => !document.querySelector('dialog'));

module('Component | canon-math-field', function (hooks) {
	setupRenderingTest(hooks);

	test('the field opens the keypad sheet and reports edits', async function (assert) {
		const changes: string[] = [];
		let completed: string | undefined;
		const change = (text: string) => changes.push(text);
		const complete = (text: string) => (completed = text);
		const handle = new CanonMathFieldHandle();
		await render(
			<template>
				<CanonMathField
					@text="x"
					@placeholder="y"
					@onChange={{change}}
					@onCompletion={{complete}}
					@handle={{handle}}
				/>
			</template>,
		);
		assert.dom('dialog').doesNotExist();
		await click('.canon-math-field');
		assert.dom('dialog.canon-math-input').exists();
		assert.true(document.querySelector('dialog')!.open);
		await click('dialog [aria-label="2"]');
		await triggerKeyEvent('dialog', 'keydown', '+');
		await triggerKeyEvent('dialog', 'keydown', '1');
		assert.deepEqual(changes, ['x*2', 'x*2+', 'x*2+1']);
		await click('dialog [aria-label="Done"]');
		await closed();
		await settled();
		assert.strictEqual(completed, 'x*2+1', 'completed');
		assert.dom('dialog').doesNotExist();
		assert.dom('.canon-math-field .canon-math-view').hasAttribute(
			'aria-label',
			'x*2+1',
			'field label',
		);

		handle.edit([{ kind: 'fraction' }]);
		await settled();
		assert.dom('dialog').exists('an insert key opens the sheet');
		assert.strictEqual(
			changes.at(-1),
			'x*2+1*()/()',
			'and types itself',
		);
		document.querySelector('dialog')!.dispatchEvent(
			new Event('cancel', { cancelable: true }),
		);
		await closed();
		await settled();
		assert.dom('dialog').doesNotExist('Escape closes it');
		assert.strictEqual(completed, 'x*2+1*()/()');
	});
});
