import { expect, test } from 'vitest';
import { reactive } from 'vue';
import CanonDetentWheel from '../../src/components/canon-detent-wheel.vue';
import CanonDetentWheelRow from '../../src/components/canon-detent-wheel-row.vue';
import {
	find,
	findAll,
	render,
	settled,
	triggerKeyEvent,
	waitUntil,
} from '../helpers/render.ts';

const names = ['Red', 'Green', 'Blue', 'Cyan', 'Magenta'];
const name = (index: number) => names[index]!;

test('draws the rows around the selection and turns with the keys', async () => {
	const state = reactive({ selected: 1 });
	const picked: number[] = [];
	const select = (index: number) => {
		picked.push(index);
		state.selected = index;
	};
	await render(
		`<div style="height: 200px; width: 240px">
      <CanonDetentWheel
        :count="names.length"
        :selected="state.selected"
        :on-select="select"
        :text="name"
        label="Colour"
        v-slot="{ index, focus }"
      >
        <CanonDetentWheelRow :focus="focus">{{ name(index) }}</CanonDetentWheelRow>
      </CanonDetentWheel>
    </div>`,
		{
			CanonDetentWheel,
			CanonDetentWheelRow,
			names,
			name,
			state,
			select,
		},
	);
	await waitUntil(() =>
		document.querySelector('.canon-detent-wheel-row'),
	);
	const wheel = find('.canon-detent-wheel');
	expect(wheel).toHaveAttribute('role', 'slider');
	expect(wheel).toHaveAttribute('aria-valuenow', '1');
	expect(wheel).toHaveAttribute('aria-valuetext', 'Green');
	expect(findAll('.canon-detent-wheel-row'), 'all fit').toHaveLength(5);
	await triggerKeyEvent('.canon-detent-wheel', 'keydown', 'ArrowDown');
	await waitUntil(() => picked.length > 0, { timeout: 2000 });
	expect(picked).toEqual([2]);
	await waitUntil(
		() =>
			findAll('.canon-detent-wheel-row').find(
				(row) =>
					row.style.getPropertyValue(
						'--canon-detent-focus',
					) === '1',
			)?.textContent === 'Blue',
	);
	expect(find('.canon-detent-wheel')).toHaveAttribute(
		'aria-valuetext',
		'Blue',
	);

	state.selected = 0;
	await settled();
	await waitUntil(
		() =>
			document
				.querySelector('.canon-detent-wheel')
				?.getAttribute('aria-valuenow') === '0',
		{ timeout: 2000 },
	);
	expect(find('.canon-detent-wheel')).toHaveAttribute(
		'aria-valuetext',
		'Red',
	);
	await triggerKeyEvent('.canon-detent-wheel', 'keydown', 'ArrowUp');
	expect(
		find('.canon-detent-wheel'),
		'stops at the first row',
	).toHaveAttribute('aria-valuenow', '0');
});
