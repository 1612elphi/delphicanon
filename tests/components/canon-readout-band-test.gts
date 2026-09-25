import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonReadoutBand, {
  readoutBandHeight,
} from '#src/components/canon-readout-band.gts';
import { css } from '../helpers/css.ts';

const playing = { playhead: 83.4, playing: true, looping: true };
const idle = {};

module('Component | canon-readout-band', function (hooks) {
  setupRenderingTest(hooks);

  test('over the strip or in a row below it', async function (assert) {
    await render(
      <template>
        <div class="over" style={{css "width: 400px; height: 120px"}}>
          <CanonReadoutBand @transport={{playing}} as |playhead|>
            <span class="strip">{{playhead}}</span>
          </CanonReadoutBand>
        </div>
        <div class="below" style={{css "width: 400px; height: 100px"}}>
          <CanonReadoutBand @transport={{idle}} @readout="below">
            <span class="strip"></span>
          </CanonReadoutBand>
        </div>
      </template>,
    );
    assert.dom('.over .strip').hasText('83.4');
    assert.dom('.over .canon-timecode').hasAria('label', 'Position');
    assert.dom('.over .canon-lamps-lamp--lit').exists({ count: 2 });
    assert.dom('.below .canon-timecode-digits').hasText('--:--.--');
    assert.dom('.below .canon-timecode').hasAria('label', 'Length');
    const strip = document.querySelector<HTMLElement>(
      '.below .canon-readout-band-strip',
    )!;
    const band = document.querySelector<HTMLElement>(
      '.below .canon-readout-band',
    )!;
    assert.strictEqual(
      band.offsetHeight - strip.offsetHeight,
      readoutBandHeight(0),
      'the readout row is 44 tall',
    );
  });
});
