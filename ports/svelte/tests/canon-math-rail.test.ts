import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Rail from './fixtures/canon-math-rail-sized.svelte';
import type { Key } from '@canon/lib/math/expression.ts';
import { click, triggerEvent } from './helpers.ts';

describe('canon-math-rail', () => {
	test('the rail steps the caret with its arrows and its ribs', async () => {
		const steps: string[] = [];
		const step = (key: Key) => (steps.push(key.kind), true);
		await render(Rail, { onStep: step });
		await click('[aria-label="Left"]');
		await click('[aria-label="Up"]');
		const ribs = '.canon-math-rail-ribs';
		await triggerEvent(ribs, 'pointerdown', {
			button: 0,
			clientX: 100,
			pointerId: 1,
		});
		await triggerEvent(ribs, 'pointermove', {
			clientX: 140,
			pointerId: 1,
		});
		await triggerEvent(ribs, 'pointerup', {
			clientX: 140,
			pointerId: 1,
		});
		expect(steps, 'one place per 16 px').toEqual([
			'left',
			'up',
			'right',
			'right',
		]);
	});
});
