import { expect, test } from 'vitest';
import CanonToast from '../../src/components/canon-toast.vue';
import { toast } from '../../src/lib/toast-store.ts';
import { fakeClipboard } from '../helpers/fake-clipboard.ts';
import { find, render, settled } from '../helpers/render.ts';

test('copy writes the text and shows it', async () => {
  const written = fakeClipboard();
  await render(`<CanonToast />`, { CanonToast });
  await toast.copy('#3B82F6');
  await settled();
  expect(written).toEqual(['#3B82F6']);
  expect(find('.canon-toast-detail')).toHaveTextContent('#3B82F6');
  expect(find('[role=status]')).toHaveTextContent('Copied');
  expect(find('.canon-toast').style.opacity).toBe('1');
});

test('a failed write shows nothing', async () => {
  toast.write = () => Promise.reject(new Error('denied'));
  await render(`<CanonToast />`, { CanonToast });
  await toast.copy('x');
  await settled();
  expect(toast.visible).toBe(false);
  expect(find('[role=status]')).toHaveTextContent('');
});

test('a long or multi-line value is left out', async () => {
  await render(`<CanonToast />`, { CanonToast });
  toast.show('one\ntwo');
  await settled();
  expect(document.querySelector('.canon-toast-detail')).toBeNull();
  expect(find('.canon-toast-title')).toHaveTextContent('Copied');
});
