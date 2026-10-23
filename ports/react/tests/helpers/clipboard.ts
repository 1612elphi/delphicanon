import { afterEach } from 'vitest';
import { canonToast } from '../../src/lib/toast-store.ts';

/** Replaces the toast store's clipboard write; returns what was written. */
export function fakeClipboard(): string[] {
	const written: string[] = [];
	canonToast.write = (text) => {
		written.push(text);
		return Promise.resolve();
	};
	return written;
}

const original = canonToast.write;
afterEach(() => {
	canonToast.write = original;
});
