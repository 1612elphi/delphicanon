import { expect, test } from 'vitest';
import CanonFileCell from '../../src/components/canon-file-cell.vue';
import { find, render, settled } from '../helpers/render.ts';

// as @ember/test-helpers' triggerEvent does for a change with files
async function choose(selector: string, files: File[]) {
  const input = find<HTMLInputElement>(selector);
  const data = new DataTransfer();
  files.forEach((file) => data.items.add(file));
  input.files = data.files;
  input.dispatchEvent(new Event('change', { bubbles: true }));
  await settled();
}

test('shows None, then the chosen file name', async () => {
  const picked: string[] = [];
  const record = (file: File) => picked.push(file.name);
  await render(`<CanonFileCell accept="image/*" :on-change="record" />`, {
    CanonFileCell,
    record,
  });
  expect(find('.canon-file-cell-name').textContent?.trim()).toBe('None');
  expect(find('input[type=file]')).toHaveAttribute('accept', 'image/*');
  expect(find('button').textContent?.trim()).toBe('Choose');
  const file = new File(['x'], 'a-rather-long-name.png', { type: 'image/png' });
  await choose('input[type=file]', [file]);
  expect(picked).toEqual(['a-rather-long-name.png']);
  expect(find('.canon-file-cell-tail').textContent?.trim()).toBe('name.png');
});
