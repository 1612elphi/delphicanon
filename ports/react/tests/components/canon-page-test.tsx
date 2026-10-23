import { describe, expect, test } from 'vitest';
import CanonCanvas from '../../src/components/canon-canvas.tsx';
import CanonPage from '../../src/components/canon-page.tsx';
import { find, render } from '../helpers/render.tsx';

describe('canon-page', () => {
	test('caps and centres sections; a canvas spans the width', async () => {
		await render(
			<div
				className="box"
				style={{ width: 1000, height: 400 }}
			>
				<CanonPage>
					<div className="section">Section</div>
					<CanonCanvas height={50} />
				</CanonPage>
			</div>,
		);
		const section = find('.section');
		expect(section.offsetWidth).toBe(720);
		expect(
			section.getBoundingClientRect().left -
				find('.box').getBoundingClientRect().left,
		).toBe(140);
		expect(find('.canon-canvas').offsetWidth).toBe(1000);
	});

	test('null maxWidth leaves only the padding', async () => {
		await render(
			<div style={{ width: 1000 }}>
				<CanonPage maxWidth={null}>
					<div className="section">S</div>
				</CanonPage>
			</div>,
		);
		expect(find('.section').offsetWidth).toBe(968);
	});
});
