import { describe, expect, test } from 'vitest';
import CanonPreviewPanel from '../../src/components/canon-preview-panel.tsx';
import { find, render } from '../helpers/render.tsx';

describe('canon-preview-panel', () => {
  test('caption and detail over the content', async () => {
    await render(
      <CanonPreviewPanel caption="Preview" detail="1600 x 900">
        <span className="art">Art</span>
      </CanonPreviewPanel>,
    );
    expect(find('figcaption').innerText.replace(/\s+/g, ' ')).toBe(
      'Preview 1600 x 900',
    );
    expect(
      document.querySelector('.canon-preview-panel-content .art'),
    ).not.toBeNull();
    const header = find('figcaption').getBoundingClientRect();
    const content = find(
      '.canon-preview-panel-content',
    ).getBoundingClientRect();
    expect(header.bottom).toBeLessThanOrEqual(content.top);
  });
});
