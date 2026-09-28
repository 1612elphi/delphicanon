import { describe, expect, test } from 'vitest';
import type { Rgb } from '@canon/lib/colour.ts';
import CanonColourCard from '../../src/components/canon-colour-card.tsx';
import { find, findAll, render } from '../helpers/render.tsx';

const grey: Rgb = [0.4667, 0.4667, 0.4667];

describe('canon-colour-card', () => {
  test('a chip shows inks with their ratios and three values', async () => {
    await render(
      <CanonColourCard colour={grey} name="Mid grey" primaryFormat="hsl" />,
    );
    expect(find('.canon-colour-card-name').textContent).toBe('Mid grey');
    expect(
      findAll('.canon-value-line-label').map((e) => e.textContent),
    ).toEqual(['HEX', 'HSL', 'RGB']);
    expect(findAll('.canon-colour-card-ratio').length).toBe(2);
    expect(
      find('.canon-colour-card-ink:first-child .canon-colour-card-ratio')
        .textContent,
    ).toBe('4.47');
    // white fails AA on this grey
    expect(find('.canon-colour-card-ink').style.opacity).toBe('0.45');
  });

  test('a row shows the name and the hex', async () => {
    await render(<CanonColourCard colour={grey} layout="row" />);
    expect(findAll('.canon-value-line').length).toBe(1);
    expect(find('.canon-colour-card-name').textContent).toBe('#777777');
    expect(document.querySelector('.canon-colour-card-ink')).toBeNull();
  });
});
