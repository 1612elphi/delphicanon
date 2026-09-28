import { describe, expect, test } from 'vitest';
import CanonTimecode from '../../src/components/canon-timecode.tsx';
import { find, render } from '../helpers/render.tsx';

const smpte = () => '01:02:03:04';

describe('canon-timecode', () => {
  test('seconds, a format, blank, and preformatted text', async () => {
    await render(
      <>
        <CanonTimecode className="a" seconds={83.4} label="Position" />
        <CanonTimecode className="b" seconds={1} format={smpte} />
        <CanonTimecode className="c" />
        <CanonTimecode className="d" text="00:00:10;02" />
      </>,
    );
    const text = (selector: string) => find(selector).textContent;
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
