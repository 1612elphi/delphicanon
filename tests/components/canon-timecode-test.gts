import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonTimecode from '#src/components/canon-timecode.gts';

const smpte = () => '01:02:03:04';

module('Component | canon-timecode', function (hooks) {
  setupRenderingTest(hooks);

  test('seconds, a format, blank, and preformatted text', async function (assert) {
    await render(
      <template>
        <CanonTimecode class="a" @seconds={{83.4}} @label="Position" />
        <CanonTimecode class="b" @seconds={{1}} @format={{smpte}} />
        <CanonTimecode class="c" />
        <CanonTimecode class="d" @text="00:00:10;02" />
      </template>,
    );
    assert.dom('.a .canon-timecode-digits').hasText('01:23.40');
    assert.dom('.a .canon-timecode-dim').hasText('0');
    assert.dom('.a').hasAria('label', 'Position');
    assert.dom('.a .canon-timecode-spoken').hasText('01:23.40');
    assert.dom('.b .canon-timecode-digits').hasText('01:02:03:04');
    assert.dom('.c .canon-timecode-digits').hasText('--:--.--');
    assert.dom('.c .canon-timecode-spoken').doesNotExist();
    assert.dom('.d .canon-timecode-digits').hasText('00:00:10.02');
  });
});
