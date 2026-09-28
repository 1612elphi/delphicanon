import { expect, test } from 'vitest';
import CanonDropZone from '../../src/components/canon-drop-zone.vue';
import {
  find,
  findAll,
  render,
  settled,
  waitUntil,
} from '../helpers/render.ts';

// 1 x 1 transparent PNG
const png = Uint8Array.from(
  atob(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
  (c) => c.charCodeAt(0),
);

function transfer(files: File[]) {
  const data = new DataTransfer();
  files.forEach((file) => data.items.add(file));
  return data;
}

async function drag(
  selector: string,
  type: string,
  dataTransfer: DataTransfer,
) {
  find(selector).dispatchEvent(
    new DragEvent(type, { bubbles: true, cancelable: true, dataTransfer }),
  );
  await settled();
}

// as @ember/test-helpers' triggerEvent does for a change with files
async function choose(selector: string, files: File[]) {
  const input = find<HTMLInputElement>(selector);
  input.files = transfer(files).files;
  input.dispatchEvent(new Event('change', { bubbles: true }));
  await settled();
}

test('decodes a dropped image and names it', async () => {
  const got: string[] = [];
  const record = (images: ImageBitmap[], names: string[]) =>
    got.push(`${names[0]} ${images[0]!.width}x${images[0]!.height}`);
  await render(`<CanonDropZone prompt="Drop" :on-images="record" />`, {
    CanonDropZone,
    record,
  });
  expect(find('.canon-drop-zone-prompt').textContent?.trim()).toBe('Drop');
  expect(findAll('button')).toHaveLength(2);
  expect(findAll('button').map((b) => b.textContent?.trim())).toContain(
    'Paste',
  );
  const dataTransfer = transfer([
    new File(['text'], 'notes.txt', { type: 'text/plain' }),
    new File([png], 'dot.png', { type: 'image/png' }),
  ]);
  await drag('.canon-drop-zone-target', 'dragenter', dataTransfer);
  expect(find('.canon-drop-zone-target')).toHaveClass(
    'canon-drop-zone-target--over',
  );
  await drag('.canon-drop-zone-target', 'drop', dataTransfer);
  expect(find('.canon-drop-zone-target')).not.toHaveClass(
    'canon-drop-zone-target--over',
  );
  await waitUntil(() => got.length > 0);
  expect(got, 'text skipped, image decoded').toEqual(['dot 1x1']);
});

test('onFiles passes files through; no Paste when off', async () => {
  const got: string[][] = [];
  const record = (files: File[]) => got.push(files.map((f) => f.name));
  await render(
    `<CanonDropZone
      prompt="Drop"
      accept=""
      :multiple="true"
      :paste="false"
      :on-files="record"
    />`,
    { CanonDropZone, record },
  );
  expect(findAll('button')).toHaveLength(1);
  expect(find('input[type=file]')).toHaveAttribute('multiple');
  await choose('input[type=file]', [
    new File(['a'], 'a.wav'),
    new File(['b'], 'b.txt'),
  ]);
  expect(got).toEqual([['a.wav', 'b.txt']]);
});
