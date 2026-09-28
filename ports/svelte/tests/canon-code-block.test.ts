import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonCodeBlock from '../src/components/canon-code-block.svelte';
import { canonToast } from '../src/lib/toast-store.svelte.ts';
import Sized from './fixtures/canon-code-block-sized.svelte';
import { click, fakeClipboard, find } from './helpers.ts';

const long = Array.from(
  { length: 40 },
  (_, i) => `line ${i} ${'lorem ipsum '.repeat(12)}`,
).join('\n');

describe('canon-code-block', () => {
  test('lines do not wrap, maxHeight caps, copy writes the code', async () => {
    const written = fakeClipboard(canonToast);
    await render(Sized, { code: long });
    const code = find('.canon-code-block-code');
    // scrolls sideways
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
    await render(CanonCodeBlock, { code: 'x' });
    const bar = find('.canon-code-block-bar');
    const code = find('.canon-code-block-code');
    expect(bar.getBoundingClientRect().top).toBeGreaterThanOrEqual(
      code.getBoundingClientRect().bottom,
    );
  });
});
