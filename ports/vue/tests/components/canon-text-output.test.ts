import { expect, test } from 'vitest';
import CanonTextOutput from '../../src/components/canon-text-output.vue';
import { fakeClipboard } from '../helpers/fake-clipboard.ts';
import { click, find, findAll, render } from '../helpers/render.ts';

test('heading, text, Share beside Copy; blank shows None', async () => {
  const written = fakeClipboard();
  await render(
    `<CanonTextOutput class="full" text="GLYPH" heading="Output" file-name="a.txt" />
    <CanonTextOutput class="blank" text=" " heading="Output" file-name="a.txt" />`,
    { CanonTextOutput },
  );
  const text = (selector: string) => find(selector).textContent.trim();
  expect(text('.full .canon-heading')).toBe('Output');
  expect(text('.full .canon-text-output-text')).toBe('GLYPH');
  expect(findAll('.full .canon-grid .canon-button')).toHaveLength(2);
  expect(text('.full .canon-button--primary')).toBe('Copy');
  await click('.full .canon-button--primary');
  expect(written).toEqual(['GLYPH']);
  expect(text('.blank .canon-empty-row')).toBe('None');
  expect(find('.blank .canon-button--primary')).toBeDisabled();
});
