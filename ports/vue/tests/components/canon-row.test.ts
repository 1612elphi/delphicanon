import { expect, test } from 'vitest';
import CanonBar from '../../src/components/canon-bar.vue';
import CanonRow from '../../src/components/canon-row.vue';
import { find, render } from '../helpers/render.ts';

test('labels its control and yields the title id', async () => {
  await render(
    `<CanonRow title="Mode" detail="Caption" form="flush" v-slot="{ titleId }">
      <button type="button" :aria-labelledby="titleId">Go</button>
    </CanonRow>`,
    { CanonRow },
  );
  expect(find('.canon-row')).toHaveClass('canon-row--flush');
  expect(find('.canon-row-title')).toHaveTextContent('Mode');
  expect(find('.canon-row-detail')).toHaveTextContent('Caption');
  const id = find('.canon-row-title').id;
  expect(find('button')).toHaveAttribute('aria-labelledby', id);
});

test('puts the control below the label when both do not fit', async () => {
  await render(
    `<div style="width: 600px" class="wide">
      <CanonRow title="Label" form="flush">
        <div style="width: 300px; height: 44px"></div>
      </CanonRow>
    </div>
    <div style="width: 300px" class="narrow">
      <CanonRow title="Label" form="flush">
        <div style="width: 300px; height: 44px"></div>
      </CanonRow>
    </div>`,
    { CanonRow },
  );
  const offset = (scope: string) =>
    find(`${scope} .canon-row-control`).offsetTop -
    find(`${scope} .canon-row-label`).offsetTop;
  expect(offset('.wide'), 'side by side').toBe(0);
  expect(offset('.narrow'), 'stacked').toBeGreaterThan(0);
});

test('a bar shrinks beside the title before the row stacks', async () => {
  await render(
    `<div style="width: 260px">
      <CanonRow title="Detail and icon">
        <CanonBar style="inline-size: 100%; max-inline-size: 160px" :share="0.5" />
      </CanonRow>
    </div>`,
    { CanonRow, CanonBar },
  );
  const label = find('.canon-row-label');
  const bar = find('.canon-bar');
  expect(bar.getBoundingClientRect().top, 'beside the title').toBeLessThan(
    label.getBoundingClientRect().bottom,
  );
  expect(bar.offsetWidth, 'shrunk').toBeLessThan(160);
});

test('a sizing title stacks a row whose own title fits', async () => {
  await render(
    `<div style="width: 300px">
      <CanonRow title="A" sizing-title="A much longer title than this row has">
        <div style="width: 120px; height: 30px"></div>
      </CanonRow>
    </div>`,
    { CanonRow },
  );
  expect(find('.canon-row-control').offsetTop).toBeGreaterThan(
    find('.canon-row-label').offsetTop,
  );
});
