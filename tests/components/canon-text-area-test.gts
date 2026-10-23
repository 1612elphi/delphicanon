import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { fillIn, render, rerender } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import CanonTextArea from '#src/components/canon-text-area.gts';

class Model {
	@tracked text = 'one';
}

module('Component | canon-text-area', function (hooks) {
	setupRenderingTest(hooks);

	test('reports typing; a new value does not replace text being typed', async function (assert) {
		const model = new Model();
		const edits: string[] = [];
		const record = (value: string) => edits.push(value);
		await render(
			<template>
				<CanonTextArea
					@value={{model.text}}
					@height={{120}}
					@placeholder="Notes"
					aria-label="Notes"
					@onChange={{record}}
				/>
			</template>,
		);
		const area =
			document.querySelector<HTMLTextAreaElement>(
				'textarea',
			)!;
		assert.strictEqual(area.value, 'one');
		assert.strictEqual(area.offsetHeight, 120);
		await fillIn('textarea', 'typed');
		assert.deepEqual(edits, ['typed']);
		model.text = 'echo';
		await rerender();
		assert.strictEqual(area.value, 'typed', 'focused: kept');
		area.blur();
		model.text = 'later';
		await rerender();
		assert.strictEqual(area.value, 'later');
	});
});
