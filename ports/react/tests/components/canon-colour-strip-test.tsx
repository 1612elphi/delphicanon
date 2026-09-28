import { describe, expect, test } from 'vitest';
import type { Rgb } from '@canon/lib/colour.ts';
import CanonColourStrip from '../../src/components/canon-colour-strip.tsx';
import { fakeClipboard } from '../helpers/clipboard.ts';
import { click, find, findAll, render } from '../helpers/render.tsx';

const red: Rgb = [1, 0, 0];
const palette: Rgb[] = [red, [0, 1, 0], [0, 0, 1]];
const nameOf = () => 'Red';

describe('canon-colour-strip', () => {
  test('shows name and value and copies the value', async () => {
    const written = fakeClipboard();
    await render(
      <CanonColourStrip colour={red} nameOf={nameOf} format="rgb" />,
    );
    expect(find('.canon-colour-strip-name').textContent).toBe('Red');
    expect(find('.canon-colour-strip-value').textContent).toBe(
      'rgb(255, 0, 0)',
    );
    await click('.canon-colour-strip-single');
    expect(written).toEqual(['rgb(255, 0, 0)']);
  });

  test('a palette shows swatches instead', async () => {
    await render(<CanonColourStrip colour={red} palette={palette} />);
    expect(findAll('.canon-swatch').length).toBe(3);
    expect(document.querySelector('.canon-colour-strip-single')).toBeNull();
  });
});
