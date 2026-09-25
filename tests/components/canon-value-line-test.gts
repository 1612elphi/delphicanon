import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import { fakeClipboard } from '../helpers/clipboard.ts';
import CanonValueLine from '#src/components/canon-value-line.gts';
import { css } from '../helpers/css.ts';

const digitsGreen = (character: string) =>
  /\d/.test(character) ? 'rgb(0, 128, 0)' : 'rgb(0, 0, 0)';

module('Component | canon-value-line', function (hooks) {
  setupRenderingTest(hooks);

  test('shows the label and value and copies the value', async function (assert) {
    const written = fakeClipboard(this.owner.lookup('service:canon-toast'));
    await render(
      <template>
        <CanonValueLine
          @label="OKLCH"
          @value="oklch(0.5 0.1 140)"
          @labelWidth={{60}}
        />
      </template>,
    );
    assert.dom('.canon-value-line-label').hasText('OKLCH');
    assert.dom('.canon-value-line-value').hasText('oklch(0.5 0.1 140)');
    assert.strictEqual(
      document.querySelector<HTMLElement>('.canon-value-line-label')!
        .offsetWidth,
      60,
    );
    await click('.canon-value-line');
    assert.deepEqual(written, ['oklch(0.5 0.1 140)']);
  });

  test('a missing value shows a dash and turns copying off', async function (assert) {
    await render(
      <template><CanonValueLine @label="Nil" @value={{null}} /></template>,
    );
    assert.dom('.canon-value-line-value').hasText('—');
    assert.dom('.canon-value-line').isDisabled();
  });

  test('layouts, lit and tint', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 240px"}}>
          <CanonValueLine
            class="above"
            @label="Above"
            @value="#1e6626"
            @layout="above"
          />
          <CanonValueLine
            class="wrapping"
            @label="x ="
            @value="#1e6626#1e6626#1e6626#1e6626"
            @layout="wrapping"
          />
          <CanonValueLine
            class="numbered"
            @label="01"
            @value="#1e6626"
            @layout="numbered"
            @lit={{true}}
            @tint={{digitsGreen}}
          />
        </div>
      </template>,
    );
    const box = (selector: string) =>
      document.querySelector<HTMLElement>(selector)!.getBoundingClientRect();
    assert.true(
      box('.above .canon-value-line-value').top >
        box('.above .canon-value-line-label').bottom - 1,
      'value under the label',
    );
    assert.true(
      box('.wrapping .canon-value-line-value').height >
        box('.wrapping .canon-value-line-label').height * 1.5,
      'the long value wraps',
    );
    assert
      .dom('.numbered')
      .hasAttribute('aria-label', '#1e6626')
      .hasAttribute('aria-current', 'true')
      .hasClass('canon-value-line--lit');
    const characters = document.querySelectorAll<HTMLElement>(
      '.numbered .canon-value-line-value span',
    );
    assert.strictEqual(characters.length, 7);
    assert.strictEqual(characters[1]!.style.color, 'rgb(0, 128, 0)');
    assert.strictEqual(characters[2]!.style.color, 'rgb(0, 0, 0)');
  });
});
