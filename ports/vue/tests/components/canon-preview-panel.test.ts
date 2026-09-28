import { expect, test } from 'vitest';
import CanonPreviewPanel from '../../src/components/canon-preview-panel.vue';
import { find, render } from '../helpers/render.ts';

// Vue drops whitespace between elements; the parts are flex items, so compare the rendered text
const shown = (selector: string) =>
  find(selector).innerText.replace(/\s+/g, ' ').trim();

test('caption and detail over the content', async () => {
  await render(
    `<CanonPreviewPanel caption="Preview" detail="1600 x 900"><span
      class="art">Art</span></CanonPreviewPanel>`,
    { CanonPreviewPanel },
  );
  expect(shown('figcaption')).toBe('Preview 1600 x 900');
  expect(
    document.querySelector('.canon-preview-panel-content .art'),
  ).not.toBeNull();
  const header = find('figcaption');
  const content = find('.canon-preview-panel-content');
  expect(
    header.getBoundingClientRect().bottom <=
      content.getBoundingClientRect().top,
    'the caption sits above the content',
  ).toBe(true);
});
