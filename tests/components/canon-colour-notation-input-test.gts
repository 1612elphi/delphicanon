import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { blur, click, fillIn, focus, render } from '@ember/test-helpers';
import CanonColourNotationInput from '#src/components/canon-colour-notation-input.gts';
import type { Rgb } from '#src/lib/colour.ts';

type EyeDropperWindow = { EyeDropper?: unknown };

const green: Rgb = [0, 1, 0];

module('Component | canon-colour-notation-input', function (hooks) {
  setupRenderingTest(hooks);

  let saved: unknown;
  hooks.beforeEach(function () {
    saved = (window as EyeDropperWindow).EyeDropper;
  });
  hooks.afterEach(function () {
    (window as EyeDropperWindow).EyeDropper = saved;
  });

  test('shows the colour, reads typed notation and marks what does not read', async function (assert) {
    const colours: Rgb[] = [];
    const use = (colour: Rgb) => colours.push(colour);
    await render(
      <template>
        <CanonColourNotationInput
          @colour={{green}}
          @onColour={{use}}
          @label="Any notation"
        />
      </template>,
    );
    assert.dom('input').hasValue('#00FF00');
    await focus('input');
    await fillIn('input', 'rgb(255 0 0)');
    await blur('input');
    assert.deepEqual(colours, [[1, 0, 0]]);
    await focus('input');
    await fillIn('input', 'not a colour');
    await blur('input');
    assert.dom('input').hasValue('not a colour').hasAttribute('aria-invalid');
    assert.dom('input').hasClass('canon-colour-notation-input--fails');
  });

  test('a parse function swaps in its own notation', async function (assert) {
    const read: string[] = [];
    const parse = (text: string) => {
      read.push(text);
      return text === 'ok';
    };
    await render(
      <template>
        <CanonColourNotationInput @text="12 34 56" @parse={{parse}} />
      </template>,
    );
    assert.dom('input').hasValue('12 34 56');
    await fillIn('input', 'ok');
    await blur('input');
    assert.dom('input').doesNotHaveAttribute('aria-invalid');
    await fillIn('input', 'nope');
    await blur('input');
    assert.dom('input').hasAttribute('aria-invalid', 'true');
    assert.deepEqual(read, ['ok', 'nope']);
  });

  test('the eyedropper picks through the EyeDropper API, and is absent without it', async function (assert) {
    (window as EyeDropperWindow).EyeDropper = class {
      open() {
        return Promise.resolve({ sRGBHex: '#0000ff' });
      }
    };
    const colours: Rgb[] = [];
    const use = (colour: Rgb) => colours.push(colour);
    await render(
      <template><CanonColourNotationInput @onColour={{use}} /></template>,
    );
    await click('.canon-button');
    assert.deepEqual(colours, [[0, 0, 1]]);

    delete (window as EyeDropperWindow).EyeDropper;
    await render(<template><CanonColourNotationInput /></template>);
    assert.dom('.canon-button').doesNotExist();
  });
});
