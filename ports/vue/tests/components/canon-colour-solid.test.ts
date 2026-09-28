import { reactive } from 'vue';
import { expect, test } from 'vitest';
import CanonColourSolid from '../../src/components/canon-colour-solid.vue';
import type { Rgb } from '@canon/lib/colour.ts';
import type { SolidSpace as Space } from '@canon/lib/colour-space.ts';
import type { Vec4 } from '@canon/lib/colour-solid/vec.ts';
import {
  find,
  findAll,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent,
  waitUntil,
} from '../helpers/render.ts';

const frame = () => new Promise((resolve) => requestAnimationFrame(resolve));
const hasWebGL2 = !!document.createElement('canvas').getContext('webgl2');

function pixel(canvas: HTMLCanvasElement, x: number, y: number) {
  const gl = canvas.getContext('webgl2')!;
  const out = new Uint8Array(4);
  gl.readPixels(x, canvas.height - 1 - y, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, out);
  return [...out];
}

function model() {
  const m = reactive({
    space: 'rgb' as Space,
    point: [0.5, 0.5, 0.5, 0] as Vec4,
    sliceAxis: null as number | null,
    picks: [] as Vec4[],
    colours: [] as Rgb[],
    onChange: (point: Vec4, colour: Rgb) => {
      m.picks.push(point);
      m.colours.push(colour);
      m.point = point;
    },
  });
  return m;
}

test('draws the solid, marks the pick, picks on a tap', async () => {
  const m = model();
  await render(
    `<div style="width: 300px; height: 300px">
      <CanonColourSolid
        :space="m.space"
        :point="m.point"
        :slice-axis="m.sliceAxis"
        :on-change="m.onChange"
      />
    </div>`,
    { CanonColourSolid, m },
  );
  await frame();
  expect(find('.canon-colour-solid')).toHaveAttribute('aria-label', 'RGB');
  expect(find('.canon-colour-solid output').textContent?.trim()).toBe(
    '#808080',
  );
  expect(find('.canon-colour-solid-marker--pick')).toBeVisible();
  expect(findAll('.canon-colour-solid-axis')).toHaveLength(3);

  const canvas = find<HTMLCanvasElement>('.canon-colour-solid-canvas');
  if (hasWebGL2) {
    expect(find('.canon-colour-solid')).toHaveAttribute('data-gl', 'ready');
    expect(canvas.width).toBe(Math.round(300 * devicePixelRatio));
    const middle = Math.round(canvas.width * 0.6);
    expect(pixel(canvas, middle, middle)[3], 'the cube is opaque').toBe(255);
    expect(pixel(canvas, 1, 1)[3], 'around it is clear').toBe(0);
  } else {
    expect(find('.canon-colour-solid')).toHaveAttribute('data-gl', 'none');
  }

  const solid = find('.canon-colour-solid');
  const box = solid.getBoundingClientRect();
  const at = {
    clientX: box.left + box.width * 0.62,
    clientY: box.top + box.height * 0.62,
    button: 0,
    pointerId: 1,
  };
  await triggerEvent(solid, 'pointerdown', at);
  await triggerEvent(solid, 'pointerup', at);
  expect(m.picks.length, 'a tap on the cube picks').toBe(1);
  await waitUntil(
    () => document.querySelector('output')?.textContent !== '#808080',
  );
  expect(find('output').textContent?.trim()).toMatch(/^#[0-9A-F]{6}$/);
});

test('a new space converts the pick; arrow keys turn it', async () => {
  const m = model();
  m.point = [1, 0, 0, 0];
  await render(
    `<div style="width: 200px; height: 200px">
      <CanonColourSolid
        :space="m.space"
        :point="m.point"
        :on-change="m.onChange"
      />
    </div>`,
    { CanonColourSolid, m },
  );
  m.space = 'hsl';
  await settled();
  await waitUntil(() => m.picks.length > 0);
  expect(m.picks[0], 'red in HSL').toEqual([0, 0.5, 1, 0]);
  expect(find('.canon-colour-solid')).toHaveAttribute('aria-label', 'HSL');

  const marker = find('.canon-colour-solid-marker--pick');
  const before = marker.style.translate;
  await triggerKeyEvent('.canon-colour-solid', 'keydown', 'ArrowRight');
  await frame();
  await frame();
  expect(marker.style.translate, 'the pick moves with the turn').not.toBe(
    before,
  );
});

test('cuts away by default, as cutsAway true', async () => {
  if (!hasWebGL2) return;
  await render(
    `<div v-for="cuts in [undefined, true, false]" style="width: 200px; height: 200px">
      <CanonColourSolid space="rgb" :point="[0.5, 0.5, 0.5, 0]" :cuts-away="cuts" />
    </div>`,
    { CanonColourSolid },
  );
  await frame();
  await frame();
  const pixels = findAll<HTMLCanvasElement>('.canon-colour-solid-canvas').map(
    (canvas) => {
      const gl = canvas.getContext('webgl2')!;
      const out = new Uint8Array(canvas.width * canvas.height * 4);
      gl.readPixels(
        0,
        0,
        canvas.width,
        canvas.height,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        out,
      );
      return out.join();
    },
  );
  expect(pixels[0], 'absent draws as true').toBe(pixels[1]);
  expect(pixels[0], 'and not as false').not.toBe(pixels[2]);
});
