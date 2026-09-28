import { describe, expect, test } from 'vitest';
import CanonTiles from '../../src/components/canon-tiles.tsx';
import { find, findAll, render, wait } from '../helpers/render.tsx';

const items = [
  { label: 'Codec', value: 'AAC' },
  { label: 'Peak', value: '-4.3 dBFS', level: 0.93 },
  { label: 'RMS', value: '-13.6 dBFS', level: 0.77 },
];

describe('canon-tiles', () => {
  test('as many columns as fit, at least two, with level bars', async () => {
    await render(
      <>
        <div className="wide" style={{ width: 600 }}>
          <CanonTiles items={items} />
        </div>
        <div className="narrow" style={{ width: 200 }}>
          <CanonTiles items={items} />
        </div>
      </>,
    );
    const columns = (selector: string) =>
      find(`${selector} .canon-grid`).style.getPropertyValue(
        '--canon-grid-columns',
      );
    for (let i = 0; i < 50 && columns('.wide') !== '3'; i++) await wait(20);
    expect(columns('.wide')).toBe('3');
    expect(columns('.narrow')).toBe('2');
    expect(findAll('.wide .canon-tiles-level')).toHaveLength(2);
    expect(find('.wide .canon-tiles-tile').innerText.replace(/\s+/g, ' ')).toBe(
      'Codec AAC',
    );
  });
});
