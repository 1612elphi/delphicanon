import { beforeEach, describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonToast from '../src/components/canon-toast.svelte';
import { canonToast as toast } from '../src/lib/toast-store.svelte.ts';
import { fakeClipboard, find, settled } from './helpers.ts';

const write = toast.write;

describe('canon-toast', () => {
	beforeEach(() => {
		toast.write = write;
		toast.visible = false;
		toast.shown = 0;
		toast.detail = undefined;
	});

	test('copy writes the text and shows it', async () => {
		const written = fakeClipboard(toast);
		await render(CanonToast);
		await toast.copy('#3B82F6');
		await settled();
		expect(written).toEqual(['#3B82F6']);
		expect(find('.canon-toast-detail').textContent).toBe('#3B82F6');
		expect(find('[role=status]').textContent).toBe('Copied');
		expect(find('.canon-toast').style.opacity).toBe('1');
	});

	test('a failed write shows nothing', async () => {
		toast.write = () => Promise.reject(new Error('denied'));
		await render(CanonToast);
		await toast.copy('x');
		await settled();
		expect(toast.visible).toBe(false);
		expect(find('[role=status]').textContent).toBe('');
	});

	test('a long or multi-line value is left out', async () => {
		await render(CanonToast);
		toast.show('one\ntwo');
		await settled();
		expect(
			document.querySelector('.canon-toast-detail'),
		).toBeNull();
		expect(find('.canon-toast-title').textContent).toBe('Copied');
	});
});
