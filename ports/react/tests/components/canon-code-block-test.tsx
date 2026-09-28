import { describe, expect, test } from 'vitest';
import CanonCodeBlock from '../../src/components/canon-code-block.tsx';
import { fakeClipboard } from '../helpers/clipboard.ts';
import { click, find, render } from '../helpers/render.tsx';

const long = Array.from(
  { length: 40 },
  (_, i) => `line ${i} ${'lorem ipsum '.repeat(12)}`,
).join('\n');

describe('canon-code-block', () => {
  test('lines do not wrap, maxHeight caps, copy writes the code', async () => {
    const written = fakeClipboard();
    await render(
      <div style={{ width: 300 }}>
        <CanonCodeBlock code={long} language="css" maxHeight={160} />
      </div>,
    );
    const code = find('.canon-code-block-code');
    expect(code.scrollWidth).toBeGreaterThan(code.clientWidth);
    expect(code.offsetHeight).toBe(160);
    expect(find('.canon-code-block-language').textContent).toBe('css');
    await click('.canon-code-block-copy');
    expect(written).toEqual([long]);
    expect(
      document.querySelector('.canon-code-block-copy--copied'),
    ).not.toBeNull();
  });

  test('without a language the copy button sits below', async () => {
    await render(<CanonCodeBlock code="x" />);
    const bar = find('.canon-code-block-bar').getBoundingClientRect();
    const code = find('.canon-code-block-code').getBoundingClientRect();
    expect(bar.top).toBeGreaterThanOrEqual(code.bottom);
  });
});
