import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, triggerEvent, waitUntil } from '@ember/test-helpers';
import CanonDropZone from '#src/components/canon-drop-zone.gts';

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

module('Component | canon-drop-zone', function (hooks) {
  setupRenderingTest(hooks);

  test('decodes a dropped image and names it', async function (assert) {
    const got: string[] = [];
    const record = (images: ImageBitmap[], names: string[]) =>
      got.push(`${names[0]} ${images[0]!.width}x${images[0]!.height}`);
    await render(
      <template>
        <CanonDropZone @prompt="Drop" @onImages={{record}} />
      </template>,
    );
    assert.dom('.canon-drop-zone-prompt').hasText('Drop');
    assert.dom('button').exists({ count: 2 });
    const dataTransfer = transfer([
      new File(['text'], 'notes.txt', { type: 'text/plain' }),
      new File([png], 'dot.png', { type: 'image/png' }),
    ]);
    await triggerEvent('.canon-drop-zone-target', 'dragenter', {
      dataTransfer,
    });
    assert
      .dom('.canon-drop-zone-target')
      .hasClass('canon-drop-zone-target--over');
    await triggerEvent('.canon-drop-zone-target', 'drop', { dataTransfer });
    assert
      .dom('.canon-drop-zone-target')
      .doesNotHaveClass('canon-drop-zone-target--over');
    await waitUntil(() => got.length > 0);
    assert.deepEqual(got, ['dot 1x1'], 'text skipped, image decoded');
  });

  test('onFiles passes files through; no Paste when off', async function (assert) {
    const got: string[][] = [];
    const record = (files: File[]) => got.push(files.map((f) => f.name));
    await render(
      <template>
        <CanonDropZone
          @prompt="Drop"
          @accept=""
          @multiple={{true}}
          @paste={{false}}
          @onFiles={{record}}
        />
      </template>,
    );
    assert.dom('button').exists({ count: 1 });
    assert.dom('input[type=file]').hasAttribute('multiple');
    await triggerEvent('input[type=file]', 'change', {
      files: [new File(['a'], 'a.wav'), new File(['b'], 'b.txt')],
    });
    assert.deepEqual(got, [['a.wav', 'b.txt']]);
  });
});
