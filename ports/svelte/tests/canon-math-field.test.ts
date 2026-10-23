import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonMathField, {
	CanonMathFieldHandle,
} from '../src/components/canon-math-field.svelte';
import { click, find, settled, triggerKeyEvent, wait } from './helpers.ts';

// the sheet closes after its 350 ms slide, which settled does not track
async function closed() {
	for (let i = 0; i < 200 && document.querySelector('dialog'); i += 1)
		await wait(10);
}

describe('canon-math-field', () => {
	test('the field opens the keypad sheet and reports edits', async () => {
		const changes: string[] = [];
		let completed: string | undefined;
		const handle = new CanonMathFieldHandle();
		await render(CanonMathField, {
			text: 'x',
			placeholder: 'y',
			onChange: (text) => changes.push(text),
			onCompletion: (text) => (completed = text),
			handle,
		});
		expect(document.querySelector('dialog')).toBeNull();
		await click('.canon-math-field');
		expect(
			document.querySelector('dialog.canon-math-input'),
		).not.toBeNull();
		expect(find<HTMLDialogElement>('dialog').open).toBe(true);
		await click('dialog [aria-label="2"]');
		await triggerKeyEvent('dialog', 'keydown', '+');
		await triggerKeyEvent('dialog', 'keydown', '1');
		expect(changes).toEqual(['x*2', 'x*2+', 'x*2+1']);
		await click('dialog [aria-label="Done"]');
		await closed();
		await settled();
		expect(completed, 'completed').toBe('x*2+1');
		expect(document.querySelector('dialog')).toBeNull();
		expect(
			find('.canon-math-field .canon-math-view').getAttribute(
				'aria-label',
			),
			'field label',
		).toBe('x*2+1');

		handle.edit([{ kind: 'fraction' }]);
		await settled();
		expect(
			document.querySelector('dialog'),
			'an insert key opens the sheet',
		).not.toBeNull();
		expect(changes.at(-1), 'and types itself').toBe('x*2+1*()/()');
		find('dialog').dispatchEvent(
			new Event('cancel', { cancelable: true }),
		);
		await closed();
		await settled();
		expect(
			document.querySelector('dialog'),
			'Escape closes it',
		).toBeNull();
		expect(completed).toBe('x*2+1*()/()');
	});
});
