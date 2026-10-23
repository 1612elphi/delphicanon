import { expect, test } from 'vitest';
import CanonReadoutBand, {
	readoutBandHeight,
} from '../../src/components/canon-readout-band.vue';
import { find, findAll, render } from '../helpers/render.ts';

const playing = { playhead: 83.4, playing: true, looping: true };
const idle = {};

test('over the strip or in a row below it', async () => {
	await render(
		`<div class="over" style="width: 400px; height: 120px">
      <CanonReadoutBand :transport="playing" v-slot="{ playhead }">
        <span class="strip">{{ playhead }}</span>
      </CanonReadoutBand>
    </div>
    <div class="below" style="width: 400px; height: 100px">
      <CanonReadoutBand :transport="idle" readout="below">
        <span class="strip"></span>
      </CanonReadoutBand>
    </div>`,
		{ CanonReadoutBand, playing, idle },
	);
	expect(find('.over .strip').textContent.trim()).toBe('83.4');
	expect(find('.over .canon-timecode')).toHaveAttribute(
		'aria-label',
		'Position',
	);
	expect(findAll('.over .canon-lamps-lamp--lit')).toHaveLength(2);
	expect(find('.below .canon-timecode-digits').textContent.trim()).toBe(
		'--:--.--',
	);
	expect(find('.below .canon-timecode')).toHaveAttribute(
		'aria-label',
		'Length',
	);
	const strip = find('.below .canon-readout-band-strip');
	const band = find('.below .canon-readout-band');
	expect(
		band.offsetHeight - strip.offsetHeight,
		'the readout row is 44 tall',
	).toBe(readoutBandHeight(0));
});
