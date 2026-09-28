import { describe, expect, test } from 'vitest';
import CanonReadoutBand, {
  readoutBandHeight,
} from '../../src/components/canon-readout-band.tsx';
import { find, findAll, render } from '../helpers/render.tsx';

const playing = { playhead: 83.4, playing: true, looping: true };
const idle = {};

describe('canon-readout-band', () => {
  test('over the strip or in a row below it', async () => {
    await render(
      <>
        <div className="over" style={{ width: 400, height: 120 }}>
          <CanonReadoutBand transport={playing}>
            {(playhead) => <span className="strip">{playhead}</span>}
          </CanonReadoutBand>
        </div>
        <div className="below" style={{ width: 400, height: 100 }}>
          <CanonReadoutBand transport={idle} readout="below">
            <span className="strip" />
          </CanonReadoutBand>
        </div>
      </>,
    );
    expect(find('.over .strip').textContent).toBe('83.4');
    expect(find('.over .canon-timecode').getAttribute('aria-label')).toBe(
      'Position',
    );
    expect(findAll('.over .canon-lamps-lamp--lit')).toHaveLength(2);
    expect(find('.below .canon-timecode-digits').textContent).toBe('--:--.--');
    expect(find('.below .canon-timecode').getAttribute('aria-label')).toBe(
      'Length',
    );
    const strip = find('.below .canon-readout-band-strip');
    const band = find('.below .canon-readout-band');
    expect(band.offsetHeight - strip.offsetHeight).toBe(readoutBandHeight(0));
  });
});
