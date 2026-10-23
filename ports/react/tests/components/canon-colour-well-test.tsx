import { describe, expect, test } from 'vitest';
import type { Rgb } from '@canon/lib/colour.ts';
import CanonColourWell from '../../src/components/canon-colour-well.tsx';
import { fillIn, find, render } from '../helpers/render.tsx';

const green: Rgb = [0, 0.5, 0];

describe('canon-colour-well', () => {
	test('a typed hex changes the colour; anything else puts it back', async () => {
		const changes: Rgb[] = [];
		await render(
			<CanonColourWell
				label="Foreground"
				colour={green}
				format="rgb"
				onChange={(colour) => changes.push(colour)}
			/>,
		);
		expect(find('.canon-colour-well-label').textContent).toBe(
			'Foreground',
		);
		expect(find<HTMLInputElement>('input[type=text]').value).toBe(
			'008000',
		);
		expect(find<HTMLInputElement>('input[type=color]').value).toBe(
			'#008000',
		);
		expect(find('.canon-colour-well-echo').textContent).toBe(
			'rgb(0, 128, 0)',
		);
		await fillIn('input[type=text]', '#ff0000');
		expect(changes).toEqual([[1, 0, 0]]);
		await fillIn('input[type=text]', 'nope');
		expect(changes.length).toBe(1);
		expect(find<HTMLInputElement>('input[type=text]').value).toBe(
			'008000',
		);
	});
});
