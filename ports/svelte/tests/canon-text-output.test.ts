import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonTextOutput from '../src/components/canon-text-output.svelte';
import { canonToast } from '../src/lib/toast-store.svelte.ts';
import { click, fakeClipboard, find, findAll } from './helpers.ts';

const text = (selector: string) =>
  find(selector).textContent.replace(/\s+/g, ' ').trim();

describe('canon-text-output', () => {
  test('heading, text, Share beside Copy; blank shows None', async () => {
    const written = fakeClipboard(canonToast);
    const props = { heading: 'Output', fileName: 'a.txt' };
    await render(CanonTextOutput, { class: 'full', text: 'GLYPH', ...props });
    await render(CanonTextOutput, { class: 'blank', text: ' ', ...props });
    expect(text('.full .canon-heading')).toBe('Output');
    expect(text('.full .canon-text-output-text')).toBe('GLYPH');
    expect(findAll('.full .canon-grid .canon-button')).toHaveLength(2);
    expect(text('.full .canon-button--primary')).toBe('Copy');
    await click('.full .canon-button--primary');
    expect(written).toEqual(['GLYPH']);
    expect(text('.blank .canon-empty-row')).toBe('None');
    expect(
      find<HTMLButtonElement>('.blank .canon-button--primary').disabled,
    ).toBe(true);
  });
});
