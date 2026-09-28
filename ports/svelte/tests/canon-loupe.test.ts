import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonLoupe from '../src/components/canon-loupe.svelte';
import { find } from './helpers.ts';

describe('canon-loupe', () => {
  test('draws the pixels unsmoothed in a frame of the colour', async () => {
    const pixels = new ImageData(3, 3);
    pixels.data.set([255, 0, 0, 255], 4 * 4);
    await render(CanonLoupe, { pixels, colour: [1, 0, 0] });
    const canvas = find<HTMLCanvasElement>('canvas');
    expect([canvas.width, canvas.height]).toEqual([3, 3]);
    expect([...canvas.getContext('2d')!.getImageData(1, 1, 1, 1).data]).toEqual(
      [255, 0, 0, 255],
    );
    expect(getComputedStyle(canvas).imageRendering).toBe('pixelated');
    const loupe = find('.canon-loupe');
    expect(getComputedStyle(loupe).borderTopColor).toBe('rgb(255, 0, 0)');
    expect(getComputedStyle(loupe).borderTopWidth).toBe('6px');
  });
});
