import { describe, expect, test } from 'vitest';
import CanonTextOutput from '../../src/components/canon-text-output.tsx';
import { fakeClipboard } from '../helpers/clipboard.ts';
import { click, find, findAll, render } from '../helpers/render.tsx';

describe('canon-text-output', () => {
  test('heading, text, Share beside Copy; blank shows None', async () => {
    const written = fakeClipboard();
    await render(
      <>
        <CanonTextOutput
          className="full"
          text="GLYPH"
          heading="Output"
          fileName="a.txt"
        />
        <CanonTextOutput
          className="blank"
          text=" "
          heading="Output"
          fileName="a.txt"
        />
      </>,
    );
    expect(find('.full .canon-heading').textContent).toBe('Output');
    expect(find('.full .canon-text-output-text').textContent).toBe('GLYPH');
    expect(findAll('.full .canon-grid .canon-button')).toHaveLength(2);
    expect(find('.full .canon-button--primary').textContent).toBe('Copy');
    await click('.full .canon-button--primary');
    expect(written).toEqual(['GLYPH']);
    expect(find('.blank .canon-empty-row').textContent).toBe('None');
    expect(
      find<HTMLButtonElement>('.blank .canon-button--primary').disabled,
    ).toBe(true);
  });
});
