import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerEvent } from '@ember/test-helpers';
import CanonButton from '#src/components/canon-button.gts';
import Dot from '../helpers/dot.gts';
import { css } from '../helpers/css.ts';

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

module('Component | canon-button', function (hooks) {
  setupRenderingTest(hooks);

  test('kinds set their heights and fill', async function (assert) {
    await render(
      <template>
        <CanonButton class="primary" @text="Go" @kind="primary" />
        <CanonButton class="secondary" @text="Go" />
        <CanonButton class="cell" @text="Go" @kind="cell" />
        <CanonButton
          class="segment"
          @text="Go"
          @kind="segment"
          @selected={{true}}
        />
      </template>,
    );
    const height = (s: string) =>
      document.querySelector<HTMLElement>(s)!.offsetHeight;
    assert.strictEqual(height('.primary'), 68);
    assert.strictEqual(height('.secondary'), 60);
    assert.strictEqual(height('.cell'), 44);
    assert.dom('.primary').hasClass('canon-button--filled');
    assert.dom('.segment').hasClass('canon-button--filled');
    assert.dom('.cell').doesNotHaveClass('canon-button--filled');
  });

  test('a disabled primary drops its fill', async function (assert) {
    await render(
      <template>
        <CanonButton
          class="off"
          @text="Go"
          @kind="primary"
          @disabled={{true}}
        />
        <span
          class="muted"
          style={{css "background: var(--canon-muted)"}}
        ></span>
        <span
          class="ink"
          style={{css "background: var(--canon-muted-foreground)"}}
        ></span>
      </template>,
    );
    const paint = (s: string) =>
      getComputedStyle(document.querySelector(s)!).backgroundColor;
    const off = getComputedStyle(document.querySelector('.off')!);
    assert.strictEqual(off.backgroundColor, paint('.muted'));
    assert.strictEqual(off.color, paint('.ink'));
  });

  test('runs onClick unless disabled', async function (assert) {
    let clicks = 0;
    const count = () => (clicks += 1);
    await render(
      <template>
        <CanonButton class="on" @text="Go" @onClick={{count}} />
        <CanonButton
          class="off"
          @text="Go"
          @onClick={{count}}
          @disabled={{true}}
        />
      </template>,
    );
    await click('.on');
    await click('.off').catch(() => undefined);
    assert.strictEqual(clicks, 1);
  });

  test('an icon-only button is named by its label', async function (assert) {
    await render(
      <template>
        <CanonButton @kind="cell" @icon={{Dot}} @label="Zoom in" />
      </template>,
    );
    assert.dom('button').hasAttribute('aria-label', 'Zoom in');
    assert.dom('button').hasClass('canon-button--symbol');
    assert.dom('.canon-button-title').doesNotExist();
  });

  test('oversized draws the icon behind the title', async function (assert) {
    await render(
      <template>
        <CanonButton @text="Wipe" @icon={{Dot}} @iconStyle="oversized" />
      </template>,
    );
    assert.dom('.canon-button-watermark svg').exists();
    assert.dom('.canon-button-icon').doesNotExist();
    assert.dom('.canon-button-title').hasText('Wipe');
  });

  test('flashesCopied shows Copied after a click', async function (assert) {
    await render(
      <template>
        <CanonButton @text="Copy" @icon={{Dot}} @flashesCopied={{true}} />
      </template>,
    );
    await click('button');
    assert.dom('.canon-button-title').hasText('Copied');
  });

  test('repeats while held; the release does not add a step', async function (assert) {
    let steps = 0;
    const step = () => (steps += 1);
    await render(
      <template>
        <CanonButton @text="+" @repeats={{true}} @onClick={{step}} />
      </template>,
    );
    await triggerEvent('button', 'pointerdown', { button: 0 });
    await wait(600);
    await triggerEvent('button', 'pointerup', { button: 0 });
    const held = steps;
    await click('button');
    assert.true(held >= 2, `${held} steps while held`);
    assert.strictEqual(steps, held);
    await click('button');
    assert.strictEqual(steps, held + 1, 'a later tap steps once');
  });
});
