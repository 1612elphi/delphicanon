import { expect, test } from 'vitest';
import { reactive } from 'vue';
import CanonCompressionScale from '../../src/components/canon-compression-scale.vue';
import { find, findAll, render, settled } from '../helpers/render.ts';

const said = () => find('.canon-figure-said').textContent;
const bars = () => findAll('.canon-compression-scale-bar');

test('the original over the result, the saving as a figure', async () => {
  const model = reactive({ before: 0, after: 0, working: false });
  await render(
    `<div style="width: 600px; height: 176px">
      <CanonCompressionScale
        :before="model.before"
        :after="model.after"
        format="JPEG"
        :working="model.working"
      />
    </div>`,
    { CanonCompressionScale, model },
  );
  expect(said(), 'a dash before a result').toBe('—');
  expect(bars()[0]).toHaveTextContent('Original');
  expect(document.querySelector('.canon-loader')).toBeNull();

  model.before = 2_400_000;
  model.working = true;
  await settled();
  expect(document.querySelector('.canon-loader')).not.toBeNull();
  expect(bars()[0]).toHaveTextContent('Original 2.3 MB');
  expect(bars()[1]).toHaveTextContent('JPEG');

  model.after = 1_200_000;
  model.working = false;
  await settled();
  expect(said()).toBe('−50%');
  expect(bars()[1]).toHaveTextContent('JPEG 1.1 MB');
  expect(bars()[1]).toHaveAttribute('data-inside');
  expect(
    bars()[1]!.style.getPropertyValue('--canon-compression-scale-share'),
  ).toBe('0.5');

  model.after = 3_600_000;
  await settled();
  expect(said()).toBe('+50%');
  expect(
    find(bars()[1]!.querySelector('.canon-bar')!).style.getPropertyValue(
      '--canon-bar-fill',
    ),
    'red when the result grew',
  ).toBe('var(--canon-destructive)');

  model.after = 24_000;
  await settled();
  expect(
    bars()[1],
    'a sliver puts the label after the fill',
  ).not.toHaveAttribute('data-inside');
});
