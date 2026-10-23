import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonTextInput from '../src/components/canon-text-input.svelte';
import { click, fillIn, find, waitUntil } from './helpers.ts';

describe('canon-text-input', () => {
	test('typing arrives after a pause, Clear at once', async () => {
		const seen: string[] = [];
		await render(CanonTextInput, {
			value: 'Hi',
			onChange: (text) => seen.push(text),
		});
		expect(find<HTMLTextAreaElement>('textarea').value).toBe('Hi');
		expect(find('textarea').getAttribute('aria-label')).toBe(
			'Input',
		);
		await fillIn('textarea', 'Hello');
		// nothing while typing
		expect(seen).toEqual([]);
		await waitUntil(() => seen.length === 1, 2000);
		expect(seen).toEqual(['Hello']);
		await click('.canon-button:last-child');
		expect(seen).toEqual(['Hello', '']);
		expect(
			find<HTMLButtonElement>('.canon-button:last-child')
				.disabled,
		).toBe(true);
	});
});
