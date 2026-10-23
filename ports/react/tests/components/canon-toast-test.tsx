import { describe, expect, test } from 'vitest';
import CanonToast from '../../src/components/canon-toast.tsx';
import { canonToast } from '../../src/lib/toast-store.ts';
import { fakeClipboard } from '../helpers/clipboard.ts';
import { find, render, settle } from '../helpers/render.tsx';

// the store is module-level: the first test sees it fresh
describe('canon-toast', () => {
	test('a failed write shows nothing', async () => {
		canonToast.write = () => Promise.reject(new Error('denied'));
		await render(<CanonToast />);
		await settle(() => canonToast.copy('x'));
		expect(find('[role=status]').textContent).toBe('');
		expect(find('.canon-toast').style.opacity).toBe('');
	});

	test('copy writes the text and shows it', async () => {
		const written = fakeClipboard();
		await render(<CanonToast />);
		await settle(() => canonToast.copy('#3B82F6'));
		expect(written).toEqual(['#3B82F6']);
		expect(find('.canon-toast-detail').textContent).toBe('#3B82F6');
		expect(find('[role=status]').textContent).toBe('Copied');
		expect(find('.canon-toast').style.opacity).toBe('1');
	});

	test('a long or multi-line value is left out', async () => {
		await render(<CanonToast />);
		await settle(() => canonToast.show('one\ntwo'));
		expect(
			document.querySelector('.canon-toast-detail'),
		).toBeNull();
		expect(find('.canon-toast-title').textContent).toBe('Copied');
	});
});
