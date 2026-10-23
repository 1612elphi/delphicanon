import { describe, expect, test } from 'vitest';
import CanonRows from '../../src/components/canon-rows.tsx';
import { find, render } from '../helpers/render.tsx';

describe('canon-rows', () => {
	test('stacks rows a hairline apart, framed on request', async () => {
		await render(
			<CanonRows framed>
				<div className="a">A</div>
				<div className="b">B</div>
			</CanonRows>,
		);
		const a = find('.a');
		const b = find('.b');
		expect(b.offsetTop - (a.offsetTop + a.offsetHeight)).toBe(1);
		expect(getComputedStyle(find('.canon-rows')).paddingTop).toBe(
			'2px',
		);
	});
});
