import { useLayoutEffect } from 'react';
import { describe, expect, test } from 'vitest';
import { hex, type Rgb } from '@canon/lib/colour.ts';
import CanonColourControls, {
	useCanonColourSolidState,
	type CanonColourSolidState,
} from '../../src/components/canon-colour-controls.tsx';
import CanonColourSolid from '../../src/components/canon-colour-solid.tsx';
import CanonRows from '../../src/components/canon-rows.tsx';
import {
	click,
	fillIn,
	find,
	findAll,
	render,
	trigger,
	waitUntil,
} from '../helpers/render.tsx';

let state: CanonColourSolidState;

function Controls({
	colour,
	activeRow,
	solid,
}: {
	colour?: Rgb;
	activeRow?: number;
	solid?: boolean;
}) {
	const current = useCanonColourSolidState({ colour, activeRow });
	useLayoutEffect(() => {
		state = current;
	});
	return (
		<div style={{ width: 400 }}>
			{solid && (
				<div style={{ height: 200 }}>
					<CanonColourSolid
						space={current.space}
						point={current.point}
						animated={current.animated}
						sliceAxis={current.sliceAxis}
						isOrtho={current.isOrtho}
						showsWhole={current.showsWhole}
						onChange={current.pick}
					/>
				</div>
			)}
			<CanonRows>
				<CanonColourControls state={current} />
			</CanonRows>
		</div>
	);
}

describe('canon-colour-controls', () => {
	test('one slider per channel, the active one the slice', async () => {
		await render(
			<Controls colour={[1, 0, 0]} activeRow={2} solid />,
		);
		expect(findAll('.canon-slider').length).toBe(3);
		expect(
			find('.canon-colour-controls-lit .canon-row-title')
				.textContent,
		).toBe('Lightness');
		// hsl lightness is axis 1
		expect(state.sliceAxis).toBe(1);
		expect(
			find<HTMLInputElement>(
				'.canon-colour-notation-input-field',
			).value,
		).toBe('#FF0000');

		const track = find(
			'.canon-slider-track',
		).getBoundingClientRect();
		const at = {
			button: 0,
			pointerId: 1,
			clientX: track.left + track.width / 3,
			clientY: track.top + track.height / 2,
		};
		await trigger('.canon-slider', 'pointerdown', at);
		await trigger('.canon-slider', 'pointerup', at);
		expect(hex(state.colour)).toBe('#00FF00');
		expect(state.activeRow).toBe(0);
		// a tap eases
		expect(state.animated).toBe(true);
		// the solid paints on the next animation frame
		await waitUntil(
			() =>
				document.querySelector(
					'.canon-colour-solid output',
				)?.textContent === '#00FF00',
		);

		await click('[role=radio]:nth-child(8)');
		expect(state.space).toBe('cmyk');
		await waitUntil(() => hex(state.colour) === '#00FF00');
		expect(findAll('.canon-slider').length).toBe(4);
		// the solid converts the pick, the colour survives
		expect(state.point.map((v) => Math.round(v * 100))).toEqual([
			100, 0, 100, 0,
		]);

		await trigger('input[role=switch]', 'click');
		expect(state.isOrtho).toBe(true);
	});

	test('reads any notation after a pause', async () => {
		await render(<Controls />);
		await fillIn(
			'.canon-colour-notation-input-field',
			'rgb(59, 130, 246)',
		);
		await waitUntil(() => hex(state.colour) === '#3B82F6', 2000);
		expect(hex(state.colour)).toBe('#3B82F6');
		await fillIn('.canon-colour-notation-input-field', 'nope');
		await waitUntil(
			() =>
				find(
					'.canon-colour-notation-input-field',
				).getAttribute('aria-invalid') === 'true',
			2000,
		);
		expect(
			find('.canon-colour-notation-input-field').getAttribute(
				'aria-invalid',
			),
		).toBe('true');
	});
});
