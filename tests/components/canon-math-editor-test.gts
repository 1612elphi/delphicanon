import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled, triggerEvent } from '@ember/test-helpers';
import CanonMathEditor from '#src/components/canon-math-editor.gts';
import { MathEditing } from '#src/lib/math/editing.ts';
import { Expression } from '#src/lib/math/expression.ts';
import { css } from '../helpers/css.ts';

module('Component | canon-math-editor', function (hooks) {
	setupRenderingTest(hooks);

	test('the editor shows a caret and places it on a click', async function (assert) {
		const editing = new MathEditing(new Expression('12+34'));
		await render(
			<template>
				<div
					style={{css
						"width: 300px; height: 112px; display: flex"
					}}
				>
					<CanonMathEditor @editing={{editing}} />
				</div>
			</template>,
		);
		assert.dom('.canon-math-editor-text').hasText('12+34');
		const caret = document.querySelector<HTMLElement>(
			'.canon-math-editor-caret',
		)!;
		const end = caret.offsetLeft;
		const content = document.querySelector<HTMLElement>(
			'.canon-math-editor-content',
		)!;
		const box = content.getBoundingClientRect();
		const scale = box.width / content.offsetWidth;
		await triggerEvent('.canon-math-editor', 'pointerdown', {
			button: 0,
			pointerId: 1,
			clientX: box.left + 17 * scale,
			clientY: box.top + box.height / 2,
		});
		await triggerEvent('.canon-math-editor', 'pointerup', {
			pointerId: 1,
		});
		assert.strictEqual(
			editing.expression.caret.index,
			0,
			'caret at the start',
		);
		assert.true(caret.offsetLeft < end);
		editing.apply({ kind: 'symbol', symbol: '9' });
		await settled();
		assert.dom('.canon-math-editor-text').hasText('912+34');
	});
});
