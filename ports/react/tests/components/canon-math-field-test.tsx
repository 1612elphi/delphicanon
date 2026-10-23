import { describe, expect, test } from 'vitest';
import CanonMathField, {
	CanonMathFieldHandle,
} from '../../src/components/canon-math-field.tsx';
import { click, find, key, render, settle, wait } from '../helpers/render.tsx';

// the sheet closes after its 250 ms slide
async function closed() {
	for (let i = 0; i < 50 && document.querySelector('dialog'); i += 1)
		await wait(20);
}

describe('canon-math-field', () => {
	test('the field opens the keypad sheet and reports edits', async () => {
		const changes: string[] = [];
		let completed: string | undefined;
		const handle = new CanonMathFieldHandle();
		await render(
			<CanonMathField
				text="x"
				placeholder="y"
				onChange={(text) => changes.push(text)}
				onCompletion={(text) => (completed = text)}
				handle={handle}
			/>,
		);
		expect(document.querySelector('dialog')).toBeNull();
		await click('.canon-math-field');
		expect(
			document.querySelector('dialog.canon-math-input'),
		).not.toBeNull();
		expect(find<HTMLDialogElement>('dialog').open).toBe(true);
		await click('dialog [aria-label="2"]');
		await key('dialog', '+');
		await key('dialog', '1');
		expect(changes).toEqual(['x*2', 'x*2+', 'x*2+1']);
		await click('dialog [aria-label="Done"]');
		await closed();
		expect(completed).toBe('x*2+1');
		expect(document.querySelector('dialog')).toBeNull();
		expect(
			find('.canon-math-field .canon-math-view').getAttribute(
				'aria-label',
			),
		).toBe('x*2+1');

		await settle(() => handle.edit([{ kind: 'fraction' }]));
		expect(document.querySelector('dialog')).not.toBeNull();
		expect(changes.at(-1)).toBe('x*2+1*()/()');
		await settle(() =>
			find('dialog').dispatchEvent(
				new Event('cancel', { cancelable: true }),
			),
		);
		await closed();
		expect(document.querySelector('dialog')).toBeNull();
		expect(completed).toBe('x*2+1*()/()');
	});
});
