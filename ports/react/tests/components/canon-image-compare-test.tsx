import { describe, expect, test } from 'vitest';
import CanonImageCompare from '../../src/components/canon-image-compare.tsx';
import { find, key, render } from '../helpers/render.tsx';

const pixel =
	'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="2" height="1"/%3E';

describe('canon-image-compare', () => {
	test('a slider with titles; keys move the divider', async () => {
		await render(
			<div style={{ width: 400, height: 200 }}>
				<CanonImageCompare
					before={pixel}
					after={pixel}
					afterTitle="Grey"
				/>
			</div>,
		);
		const slider = () => find('[role=slider]');
		expect(slider().getAttribute('aria-valuenow')).toBe('50');
		expect(slider().getAttribute('aria-label')).toBe(
			'Before, Grey',
		);
		expect(
			find('.canon-image-compare-tag--after').textContent,
		).toBe('Grey');
		await key('[role=slider]', 'ArrowRight');
		expect(slider().getAttribute('aria-valuenow')).toBe('60');
		await key('[role=slider]', 'Home');
		expect(slider().getAttribute('aria-valuetext')).toBe('0%');
	});

	test('a failure dims the original and hides the divider', async () => {
		await render(
			<CanonImageCompare
				before={pixel}
				failed
				failure="No"
			/>,
		);
		expect(document.querySelector('[role=slider]')).toBeNull();
		expect(
			document.querySelector('.canon-image-compare-divider'),
		).toBeNull();
		expect(find('.canon-image-compare-failure').textContent).toBe(
			'No',
		);
	});
});
