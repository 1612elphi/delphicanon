import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  render,
  rerender,
  triggerEvent,
  triggerKeyEvent,
  waitUntil,
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import CanonColourSolid from '#src/components/canon-colour-solid.gts';
import type { Rgb, Space } from '#src/lib/colour-solid/space.ts';
import type { Vec4 } from '#src/lib/colour-solid/vec.ts';
import { css } from '../helpers/css.ts';

const frame = () => new Promise((resolve) => requestAnimationFrame(resolve));
const hasWebGL2 = !!document.createElement('canvas').getContext('webgl2');

function pixel(canvas: HTMLCanvasElement, x: number, y: number) {
  const gl = canvas.getContext('webgl2')!;
  const out = new Uint8Array(4);
  gl.readPixels(x, canvas.height - 1 - y, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, out);
  return [...out];
}

class Model {
  @tracked space: Space = 'rgb';
  @tracked point: Vec4 = [0.5, 0.5, 0.5, 0];
  @tracked sliceAxis: number | null = null;
  picks: Vec4[] = [];
  colours: Rgb[] = [];
  onChange = (point: Vec4, colour: Rgb) => {
    this.picks.push(point);
    this.colours.push(colour);
    this.point = point;
  };
}

module('Component | canon-colour-solid', function (hooks) {
  setupRenderingTest(hooks);

  test('draws the solid, marks the pick, picks on a tap', async function (assert) {
    const model = new Model();
    await render(
      <template>
        <div style={{css "width: 300px; height: 300px"}}>
          <CanonColourSolid
            @space={{model.space}}
            @point={{model.point}}
            @sliceAxis={{model.sliceAxis}}
            @onChange={{model.onChange}}
          />
        </div>
      </template>,
    );
    await frame();
    assert.dom('.canon-colour-solid').hasAttribute('aria-label', 'RGB');
    assert.dom('.canon-colour-solid output').hasText('#808080');
    assert.dom('.canon-colour-solid-marker--pick').isVisible();
    assert.dom('.canon-colour-solid-axis').exists({ count: 3 });

    const canvas = document.querySelector<HTMLCanvasElement>(
      '.canon-colour-solid-canvas',
    )!;
    if (hasWebGL2) {
      assert.dom('.canon-colour-solid').hasAttribute('data-gl', 'ready');
      assert.strictEqual(canvas.width, Math.round(300 * devicePixelRatio));
      const middle = Math.round(canvas.width * 0.6);
      assert.strictEqual(
        pixel(canvas, middle, middle)[3],
        255,
        'the cube is opaque',
      );
      assert.strictEqual(pixel(canvas, 1, 1)[3], 0, 'around it is clear');
    } else {
      assert.dom('.canon-colour-solid').hasAttribute('data-gl', 'none');
    }

    const solid = document.querySelector<HTMLElement>('.canon-colour-solid')!;
    const box = solid.getBoundingClientRect();
    const at = {
      clientX: box.left + box.width * 0.62,
      clientY: box.top + box.height * 0.62,
      button: 0,
      pointerId: 1,
    };
    await triggerEvent(solid, 'pointerdown', at);
    await triggerEvent(solid, 'pointerup', at);
    assert.strictEqual(model.picks.length, 1, 'a tap on the cube picks');
    await waitUntil(
      () => document.querySelector('output')?.textContent !== '#808080',
    );
    assert.dom('output').hasText(/^#[0-9A-F]{6}$/);
  });

  test('a new space converts the pick; arrow keys turn it', async function (assert) {
    const model = new Model();
    model.point = [1, 0, 0, 0];
    await render(
      <template>
        <div style={{css "width: 200px; height: 200px"}}>
          <CanonColourSolid
            @space={{model.space}}
            @point={{model.point}}
            @onChange={{model.onChange}}
          />
        </div>
      </template>,
    );
    model.space = 'hsl';
    await rerender();
    await waitUntil(() => model.picks.length > 0);
    assert.deepEqual(model.picks[0], [0, 0.5, 1, 0], 'red in HSL');
    assert.dom('.canon-colour-solid').hasAttribute('aria-label', 'HSL');

    const marker = document.querySelector<HTMLElement>(
      '.canon-colour-solid-marker--pick',
    )!;
    const before = marker.style.translate;
    await triggerKeyEvent('.canon-colour-solid', 'keydown', 'ArrowRight');
    await frame();
    await frame();
    assert.notStrictEqual(
      marker.style.translate,
      before,
      'the pick moves with the turn',
    );
  });
});
