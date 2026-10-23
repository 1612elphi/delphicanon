import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Names from './fixtures/canon-detent-wheel-names.svelte';
import {
	find,
	findAll,
	settled,
	triggerKeyEvent,
	waitUntil,
} from './helpers.ts';

const names = ['Red', 'Green', 'Blue', 'Cyan', 'Magenta'];

describe('canon-detent-wheel', () => {
	test('draws the rows around the selection and turns with the keys', async () => {
		const picked: number[] = [];
		const { rerender } = await render(Names, {
			names,
			selected: 1,
			onSelect: (index: number) => picked.push(index),
		});
		await waitUntil(
			() =>
				!!document.querySelector(
					'.canon-detent-wheel-row',
				),
		);
		const wheel = find('.canon-detent-wheel');
		expect(wheel.getAttribute('role')).toBe('slider');
		expect(wheel.getAttribute('aria-valuenow')).toBe('1');
		expect(wheel.getAttribute('aria-valuetext')).toBe('Green');
		expect(
			findAll('.canon-detent-wheel-row'),
			'all fit',
		).toHaveLength(5);
		await triggerKeyEvent(
			'.canon-detent-wheel',
			'keydown',
			'ArrowDown',
		);
		await waitUntil(() => picked.length > 0, 2000);
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
		expect(wheel.getAttribute('aria-valuetext')).toBe('Blue');

		await rerender({ selected: 0 });
		await settled();
		await waitUntil(
			() => wheel.getAttribute('aria-valuenow') === '0',
			2000,
		);
		expect(wheel.getAttribute('aria-valuetext')).toBe('Red');
		await triggerKeyEvent(
			'.canon-detent-wheel',
			'keydown',
			'ArrowUp',
		);
		expect(
			wheel.getAttribute('aria-valuenow'),
			'stops at the first row',
		).toBe('0');
	});
});
