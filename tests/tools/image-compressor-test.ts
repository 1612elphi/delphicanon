import { module, test } from 'qunit';
import {
  availableFormats,
  encode,
  exportName,
  formatBytes,
  formats,
  savingsFigure,
  savingsPercent,
} from '../../demo-app/components/tools/image-compressor/compress.ts';

const format = (label: string) => formats.find((f) => f.label === label)!;

async function transparentPng(width: number, height: number) {
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const blob = await new Promise<Blob | null>((resolve) =>
    canvas.toBlob(resolve, 'image/png'),
  );
  return blob!;
}

module('Unit | tools/image-compressor', function () {
  test('savings carry the sign of the change', function (assert) {
    assert.strictEqual(savingsPercent(1000, 400), -60);
    assert.strictEqual(savingsPercent(1000, 1500), 50);
    assert.strictEqual(savingsPercent(0, 100), 0);
    assert.strictEqual(savingsFigure(1000, 1000), '±0');
    assert.strictEqual(savingsFigure(1000, 400), '−60');
    assert.strictEqual(savingsFigure(1000, 1500), '+50');
  });

  test('bytes and names', function (assert) {
    assert.strictEqual(formatBytes(512), '512 B');
    assert.strictEqual(formatBytes(1536), '1.5 KB');
    assert.strictEqual(formatBytes(3 * 1024 * 1024), '3.0 MB');
    assert.strictEqual(exportName('photo.heic', format('JPEG')), 'photo.jpg');
    assert.strictEqual(exportName('a.b.png', format('WebP')), 'a.b.webp');
    assert.strictEqual(exportName('noext', format('PNG')), 'noext.png');
    assert.strictEqual(exportName('.png', format('PNG')), '.png.png');
    assert.strictEqual(exportName('', format('JPEG')), 'image.jpg');
  });

  test('JPEG and PNG are always available', function (assert) {
    const labels = availableFormats().map((f) => f.label);
    assert.ok(labels.includes('JPEG') && labels.includes('PNG'));
  });

  test('JPEG flattens transparency on white', async function (assert) {
    const reply = await encode({
      job: 7,
      source: -1,
      file: await transparentPng(4, 2),
      type: 'image/jpeg',
      quality: 90,
    });
    assert.strictEqual(reply.job, 7);
    if ('error' in reply) return assert.ok(false, reply.error);
    assert.strictEqual(reply.blob.type, 'image/jpeg');
    assert.deepEqual([reply.width, reply.height], [4, 2]);
    const bitmap = await createImageBitmap(reply.blob);
    const canvas = document.createElement('canvas');
    canvas.width = canvas.height = 1;
    const context = canvas.getContext('2d')!;
    context.drawImage(bitmap, 0, 0, 1, 1);
    const [r, g, b] = context.getImageData(0, 0, 1, 1).data;
    assert.ok(r! > 250 && g! > 250 && b! > 250, `${r} ${g} ${b}`);
  });

  test('a file that is not an image replies with an error', async function (assert) {
    const reply = await encode({
      job: 1,
      source: -2,
      file: new Blob(['not an image'], { type: 'image/png' }),
      type: 'image/png',
      quality: 75,
    });
    assert.ok('error' in reply);
  });
});
