import { useState } from 'react';
import { describe, expect, test } from 'vitest';
import CanonDetentWheel from '../../src/components/canon-detent-wheel.tsx';
import CanonDetentWheelRow from '../../src/components/canon-detent-wheel-row.tsx';
import {
	find,
	findAll,
	key,
	render,
	settle,
	waitUntil,
} from '../helpers/render.tsx';

const names = ['Red', 'Green', 'Blue', 'Cyan', 'Magenta'];
const name = (index: number) => names[index]!;

describe('canon-detent-wheel', () => {
	test('draws the rows around the selection and turns with the keys', async () => {
		const picked: number[] = [];
		let setSelected: (index: number) => void = () => undefined;
		function Wheel() {
			const [selected, set] = useState(1);
			setSelected = set;
			return (
				<div style={{ height: 200, width: 240 }}>
					<CanonDetentWheel
						count={names.length}
						selected={selected}
						onSelect={(index) => {
							picked.push(index);
							set(index);
						}}
						text={name}
						label="Colour"
					>
						{(index, focus) => (
							<CanonDetentWheelRow
								focus={focus}
							>
								{name(index)}
							</CanonDetentWheelRow>
						)}
					</CanonDetentWheel>
				</div>
			);
		}
		await render(<Wheel />);
		await waitUntil(
			() =>
				document.querySelector(
					'.canon-detent-wheel-row',
				) !== null,
		);
		const wheel = find('.canon-detent-wheel');
		expect(wheel.getAttribute('role')).toBe('slider');
		expect(wheel.getAttribute('aria-valuenow')).toBe('1');
		expect(wheel.getAttribute('aria-valuetext')).toBe('Green');
		// all fit
		expect(findAll('.canon-detent-wheel-row').length).toBe(5);
		await key(wheel, 'ArrowDown');
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
			2000,
		);
		expect(wheel.getAttribute('aria-valuetext')).toBe('Blue');

		await settle(() => setSelected(0));
		await waitUntil(
			() => wheel.getAttribute('aria-valuenow') === '0',
			2000,
		);
		expect(wheel.getAttribute('aria-valuetext')).toBe('Red');
		await key(wheel, 'ArrowUp');
		// stops at the first row
		expect(wheel.getAttribute('aria-valuenow')).toBe('0');
	});
});
