import { describe, expect, test } from 'vitest';
import CanonButton from '../../src/components/canon-button.tsx';
import CanonGrid from '../../src/components/canon-grid.tsx';
import Dot from '../helpers/dot.tsx';
import { find, findAll, render, settle } from '../helpers/render.tsx';

const nextFrame = () =>
  new Promise((resolve) => requestAnimationFrame(() => resolve(undefined)));

describe('canon-grid', () => {
  test('balances rows: four cells at three columns are two rows of two', async () => {
    await render(
      <div style={{ width: 300 }}>
        <CanonGrid columns={3}>
          <div>1</div>
          <div>2</div>
          <div>3</div>
          <div>4</div>
        </CanonGrid>
      </div>,
    );
    const cells = findAll('.canon-grid > div');
    expect(cells.map((c) => c.offsetTop > cells[0]!.offsetTop)).toEqual([
      false,
      false,
      true,
      true,
    ]);
    expect(cells[0]!.offsetWidth).toBe(cells[3]!.offsetWidth);
  });

  test('the last cell of a short row spans the rest', async () => {
    await render(
      <div style={{ width: 302 }}>
        <CanonGrid columns={3}>
          <div>1</div>
          <div>2</div>
          <div>3</div>
          <div>4</div>
          <div>5</div>
        </CanonGrid>
      </div>,
    );
    const cells = findAll('.canon-grid > div');
    expect(cells[3]!.offsetWidth).toBe(cells[0]!.offsetWidth);
    expect(cells[4]!.offsetWidth).toBe(cells[1]!.offsetWidth * 2 + 1);
  });

  test('filling buttons drop their titles together when one does not fit', async () => {
    const buttons = (
      <CanonGrid>
        <CanonButton text="Loop" icon={<Dot />} />
        <CanonButton text="Shuffle" icon={<Dot />} />
        <CanonButton text="Export" icon={<Dot />} />
      </CanonGrid>
    );
    await render(
      <>
        <div className="narrow" style={{ width: 240 }}>
          {buttons}
        </div>
        <div className="wide" style={{ width: 900 }}>
          {buttons}
        </div>
      </>,
    );
    await settle(nextFrame);
    expect(find('.narrow .canon-grid').hasAttribute('data-symbol-only')).toBe(
      true,
    );
    expect(find('.narrow .canon-button-title').checkVisibility()).toBe(false);
    expect(find('.narrow .canon-button').getAttribute('aria-label')).toBe(
      'Loop',
    );
    expect(find('.wide .canon-grid').hasAttribute('data-symbol-only')).toBe(
      false,
    );
  });

  test('a popover beside its trigger is no cell', async () => {
    await render(
      <div style={{ width: 300 }}>
        <CanonGrid>
          <div>1</div>
          <div>2</div>
          <div popover="auto">Panel</div>
        </CanonGrid>
      </div>,
    );
    expect(
      find('.canon-grid').style.getPropertyValue('--canon-grid-columns'),
    ).toBe('2');
  });
});
