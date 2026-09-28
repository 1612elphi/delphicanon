import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonTimecode from '../src/components/canon-timecode.svelte';
import { find } from './helpers.ts';

const smpte = () => '01:02:03:04';
const text = (selector: string) => find(selector).textContent.trim();

describe('canon-timecode', () => {
  test('seconds, a format, blank, and preformatted text', async () => {
    await render(CanonTimecode, {
      class: 'a',
      seconds: 83.4,
      label: 'Position',
    });
    await render(CanonTimecode, { class: 'b', seconds: 1, format: smpte });
    await render(CanonTimecode, { class: 'c' });
    await render(CanonTimecode, { class: 'd', text: '00:00:10;02' });
    expect(text('.a .canon-timecode-digits')).toBe('01:23.40');
    expect(text('.a .canon-timecode-dim')).toBe('0');
    expect(find('.a').getAttribute('aria-label')).toBe('Position');
    expect(text('.a .canon-timecode-spoken')).toBe('01:23.40');
    expect(text('.b .canon-timecode-digits')).toBe('01:02:03:04');
    expect(text('.c .canon-timecode-digits')).toBe('--:--.--');
    expect(document.querySelector('.c .canon-timecode-spoken')).toBeNull();
    expect(text('.d .canon-timecode-digits')).toBe('00:00:10.02');
  });
});
