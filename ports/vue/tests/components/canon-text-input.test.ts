import { expect, test } from 'vitest';
import CanonTextInput from '../../src/components/canon-text-input.vue';
import { click, fillIn, find, render, waitUntil } from '../helpers/render.ts';

test('typing arrives after a pause, Clear at once', async () => {
	const seen: string[] = [];
	const onChange = (text: string) => seen.push(text);
	await render(`<CanonTextInput value="Hi" :on-change="onChange" />`, {
		CanonTextInput,
		onChange,
	});
	expect(find('textarea')).toHaveValue('Hi');
	expect(find('textarea')).toHaveAttribute('aria-label', 'Input');
	await fillIn('textarea', 'Hello');
	expect(seen, 'nothing while typing').toEqual([]);
	await waitUntil(() => seen.length === 1, { timeout: 2000 });
	expect(seen).toEqual(['Hello']);
	await click('.canon-button:last-child');
	expect(seen).toEqual(['Hello', '']);
	expect(find('.canon-button:last-child')).toBeDisabled();
});
