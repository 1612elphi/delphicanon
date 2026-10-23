import { toast } from '../../src/lib/toast-store.ts';

/** Replaces the toast store's clipboard write; returns what was written. */
export function fakeClipboard(): string[] {
	const written: string[] = [];
	toast.write = (text) => {
		written.push(text);
		return Promise.resolve();
	};
	return written;
}
