import type CanonToastService from '#src/services/canon-toast.ts';

/** Replaces the toast service's clipboard write; returns what was written. */
export function fakeClipboard(toast: CanonToastService): string[] {
  const written: string[] = [];
  toast.write = (text) => {
    written.push(text);
    return Promise.resolve();
  };
  return written;
}
