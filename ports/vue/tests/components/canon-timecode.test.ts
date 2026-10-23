import { expect, test } from 'vitest';
import CanonTimecode from '../../src/components/canon-timecode.vue';
import { find, render } from '../helpers/render.ts';

const smpte = () => '01:02:03:04';
const text = (selector: string) => find(selector).textContent.trim();

test('seconds, a format, blank, and preformatted text', async () => {
	await render(
		`<CanonTimecode class="a" :seconds="83.4" label="Position" />
    <CanonTimecode class="b" :seconds="1" :format="smpte" />
    <CanonTimecode class="c" />
    <CanonTimecode class="d" text="00:00:10;02" />`,
		{ CanonTimecode, smpte },
	);
	expect(text('.a .canon-timecode-digits')).toBe('01:23.40');
	expect(text('.a .canon-timecode-dim')).toBe('0');
	expect(find('.a')).toHaveAttribute('aria-label', 'Position');
	expect(text('.a .canon-timecode-spoken')).toBe('01:23.40');
	expect(text('.b .canon-timecode-digits')).toBe('01:02:03:04');
	expect(text('.c .canon-timecode-digits')).toBe('--:--.--');
	expect(document.querySelector('.c .canon-timecode-spoken')).toBeNull();
	expect(text('.d .canon-timecode-digits')).toBe('00:00:10.02');
});
