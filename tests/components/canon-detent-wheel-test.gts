import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
	render,
	rerender,
	triggerKeyEvent,
	waitUntil,
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import CanonDetentWheel from '#src/components/canon-detent-wheel.gts';
import CanonDetentWheelRow from '#src/components/canon-detent-wheel-row.gts';
import { css } from '../helpers/css.ts';

const names = ['Red', 'Green', 'Blue', 'Cyan', 'Magenta'];
const name = (index: number) => names[index]!;

class State {
	@tracked selected = 1;
}

module('Component | canon-detent-wheel', function (hooks) {
	setupRenderingTest(hooks);

	test('draws the rows around the selection and turns with the keys', async function (assert) {
		const state = new State();
		const picked: number[] = [];
		const select = (index: number) => {
			picked.push(index);
			state.selected = index;
		};
		await render(
			<template>
				<div
					style={{css
						"height: 200px; width: 240px"
					}}
				>
					<CanonDetentWheel
						@count={{names.length}}
						@selected={{state.selected}}
						@onSelect={{select}}
						@text={{name}}
						@label="Colour"
						as |index focus|
					>
						<CanonDetentWheelRow
							@focus={{focus}}
						>{{name
								index
							}}</CanonDetentWheelRow>
					</CanonDetentWheel>
				</div>
			</template>,
		);
		await waitUntil(() =>
			document.querySelector('.canon-detent-wheel-row'),
		);
		assert.dom('.canon-detent-wheel')
			.hasAttribute('role', 'slider')
			.hasAttribute('aria-valuenow', '1')
			.hasAttribute('aria-valuetext', 'Green');
		assert.dom('.canon-detent-wheel-row').exists(
			{ count: 5 },
			'all fit',
		);
		await triggerKeyEvent(
			'.canon-detent-wheel',
			'keydown',
			'ArrowDown',
		);
		await waitUntil(() => picked.length > 0, { timeout: 2000 });
		assert.deepEqual(picked, [2]);
		await waitUntil(() => {
			const rows = [
				...document.querySelectorAll<HTMLElement>(
					'.canon-detent-wheel-row',
				),
			];
			return (
				rows.find(
					(row) =>
						row.style.getPropertyValue(
							'--canon-detent-focus',
						) === '1',
				)?.textContent === 'Blue'
			);
		});
		assert.dom('.canon-detent-wheel').hasAttribute(
			'aria-valuetext',
			'Blue',
		);

		state.selected = 0;
		await rerender();
		await waitUntil(
			() =>
				document
					.querySelector('.canon-detent-wheel')
					?.getAttribute('aria-valuenow') === '0',
			{ timeout: 2000 },
		);
		assert.dom('.canon-detent-wheel').hasAttribute(
			'aria-valuetext',
			'Red',
		);
		await triggerKeyEvent(
			'.canon-detent-wheel',
			'keydown',
			'ArrowUp',
		);
		assert.dom('.canon-detent-wheel').hasAttribute(
			'aria-valuenow',
			'0',
			'stops at the first row',
		);
	});
});
