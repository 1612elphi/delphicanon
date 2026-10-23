import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import { readoutBandHeight } from '../src/components/canon-readout-band.svelte';
import Forms from './fixtures/canon-readout-band-forms.svelte';
import { find, findAll } from './helpers.ts';

describe('canon-readout-band', () => {
	test('over the strip or in a row below it', async () => {
		await render(Forms);
		expect(find('.over .strip').textContent).toBe('83.4');
		expect(
			find('.over .canon-timecode').getAttribute(
				'aria-label',
			),
		).toBe('Position');
		expect(findAll('.over .canon-lamps-lamp--lit')).toHaveLength(2);
		expect(
			find(
				'.below .canon-timecode-digits',
			).textContent.trim(),
		).toBe('--:--.--');
		expect(
			find('.below .canon-timecode').getAttribute(
				'aria-label',
			),
		).toBe('Length');
		const strip = find('.below .canon-readout-band-strip');
		const band = find('.below .canon-readout-band');
		// the readout row is 44 tall
		expect(band.offsetHeight - strip.offsetHeight).toBe(
			readoutBandHeight(0),
		);
	});
});
