import { describe, expect, test } from 'vitest';
import CanonSegmented from '../../src/components/canon-segmented.tsx';
import Dot from '../helpers/dot.tsx';
import { click, find, findAll, render } from '../helpers/render.tsx';

const modes = ['Region', 'Window', 'Screen'];

describe('canon-segmented', () => {
	test('picks one and reports it', async () => {
		const picks: number[] = [];
		await render(
			<CanonSegmented
				items={modes}
				selected={0}
				onChange={(index) => picks.push(index)}
			/>,
		);
		expect(findAll('[role=radio]')).toHaveLength(3);
		await click('[role=radio]:nth-child(2)');
		expect(picks).toEqual([1]);
		expect(
			find('[role=radio]:nth-child(2)').getAttribute(
				'aria-checked',
			),
		).toBe('true');
		expect(
			find('[role=radio]:nth-child(1)').getAttribute(
				'aria-checked',
			),
		).toBe('false');
		await click('[role=radio]:nth-child(2)');
		expect(picks).toEqual([1]);
	});

	test('greys single choices and shows symbols', async () => {
		await render(
			<CanonSegmented
				items={modes}
				icons={[
					<Dot key={0} />,
					<Dot key={1} />,
					<Dot key={2} />,
				]}
				disabledIndices={[2]}
			/>,
		);
		expect(
			find<HTMLButtonElement>('[role=radio]:nth-child(3)')
				.disabled,
		).toBe(true);
		expect(
			find<HTMLButtonElement>('[role=radio]:nth-child(1)')
				.disabled,
		).toBe(false);
		expect(
			find('[role=radio]:nth-child(1)').getAttribute(
				'aria-label',
			),
		).toBe('Region');
	});
});
