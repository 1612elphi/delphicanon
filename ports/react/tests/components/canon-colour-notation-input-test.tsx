import { afterEach, beforeEach, describe, expect, test } from 'vitest';
import type { Rgb } from '@canon/lib/colour.ts';
import CanonColourNotationInput from '../../src/components/canon-colour-notation-input.tsx';
import {
  blur,
  click,
  fillIn,
  find,
  focus,
  render,
} from '../helpers/render.tsx';

type EyeDropperWindow = { EyeDropper?: unknown };

const green: Rgb = [0, 1, 0];

describe('canon-colour-notation-input', () => {
  let saved: unknown;
  beforeEach(() => {
    saved = (window as EyeDropperWindow).EyeDropper;
  });
  afterEach(() => {
    (window as EyeDropperWindow).EyeDropper = saved;
  });

  test('shows the colour, reads typed notation and marks what does not read', async () => {
    const colours: Rgb[] = [];
    await render(
      <CanonColourNotationInput
        colour={green}
        onColour={(colour) => colours.push(colour)}
        label="Any notation"
      />,
    );
    const input = find<HTMLInputElement>('input');
    expect(input.value).toBe('#00FF00');
    await focus('input');
    await fillIn('input', 'rgb(255 0 0)');
    await blur('input');
    expect(colours).toEqual([[1, 0, 0]]);
    await focus('input');
    await fillIn('input', 'not a colour');
    await blur('input');
    expect(input.value).toBe('not a colour');
    expect(input.hasAttribute('aria-invalid')).toBe(true);
    expect(input.classList).toContain('canon-colour-notation-input--fails');
  });

  test('a parse function swaps in its own notation', async () => {
    const read: string[] = [];
    const parse = (text: string) => {
      read.push(text);
      return text === 'ok';
    };
    await render(<CanonColourNotationInput text="12 34 56" parse={parse} />);
    const input = find<HTMLInputElement>('input');
    expect(input.value).toBe('12 34 56');
    await fillIn('input', 'ok');
    await blur('input');
    expect(input.hasAttribute('aria-invalid')).toBe(false);
    await fillIn('input', 'nope');
    await blur('input');
    expect(input.getAttribute('aria-invalid')).toBe('true');
    expect(read).toEqual(['ok', 'nope']);
  });

  test('the eyedropper picks through the EyeDropper API, and is absent without it', async () => {
    (window as EyeDropperWindow).EyeDropper = class {
      open() {
        return Promise.resolve({ sRGBHex: '#0000ff' });
      }
    };
    const colours: Rgb[] = [];
    const { unmount } = await render(
      <CanonColourNotationInput onColour={(colour) => colours.push(colour)} />,
    );
    await click('.canon-button');
    expect(colours).toEqual([[0, 0, 1]]);
    unmount();

    delete (window as EyeDropperWindow).EyeDropper;
    await render(<CanonColourNotationInput />);
    expect(document.querySelector('.canon-button')).toBeNull();
  });
});
