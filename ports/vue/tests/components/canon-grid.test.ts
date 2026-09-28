import { expect, test } from 'vitest';
import CanonButton from '../../src/components/canon-button.vue';
import CanonGrid from '../../src/components/canon-grid.vue';
import Dot from '../helpers/dot.ts';
import { find, findAll, render, settled } from '../helpers/render.ts';

const nextFrame = () =>
  new Promise((resolve) => requestAnimationFrame(() => resolve(undefined)));

test('balances rows: four cells at three columns are two rows of two', async () => {
  await render(
    `<div style="width: 300px">
      <CanonGrid :columns="3">
        <div>1</div><div>2</div><div>3</div><div>4</div>
      </CanonGrid>
    </div>`,
    { CanonGrid },
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
    `<div style="width: 302px">
      <CanonGrid :columns="3">
        <div>1</div><div>2</div><div>3</div><div>4</div><div>5</div>
      </CanonGrid>
    </div>`,
    { CanonGrid },
  );
  const cells = findAll('.canon-grid > div');
  expect(cells[3]!.offsetWidth).toBe(cells[0]!.offsetWidth);
  expect(cells[4]!.offsetWidth).toBe(cells[1]!.offsetWidth * 2 + 1);
});

test('filling buttons drop their titles together when one does not fit', async () => {
  await render(
    `<div class="narrow" style="width: 240px">
      <CanonGrid>
        <CanonButton text="Loop" :icon="Dot" />
        <CanonButton text="Shuffle" :icon="Dot" />
        <CanonButton text="Export" :icon="Dot" />
      </CanonGrid>
    </div>
    <div class="wide" style="width: 900px">
      <CanonGrid>
        <CanonButton text="Loop" :icon="Dot" />
        <CanonButton text="Shuffle" :icon="Dot" />
        <CanonButton text="Export" :icon="Dot" />
      </CanonGrid>
    </div>`,
    { CanonGrid, CanonButton, Dot },
  );
  await nextFrame();
  await settled();
  expect(find('.narrow .canon-grid')).toHaveAttribute('data-symbol-only');
  expect(find('.narrow .canon-button-title')).not.toBeVisible();
  expect(find('.narrow .canon-button')).toHaveAttribute('aria-label', 'Loop');
  expect(find('.wide .canon-grid')).not.toHaveAttribute('data-symbol-only');
});
