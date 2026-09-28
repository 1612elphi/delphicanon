import { expect, test } from 'vitest';
import CanonSegmented from '../../src/components/canon-segmented.vue';
import Dot from '../helpers/dot.ts';
import { click, find, findAll, render } from '../helpers/render.ts';

const modes = ['Region', 'Window', 'Screen'];

test('picks one and reports it', async () => {
  const picks: number[] = [];
  const pick = (index: number) => picks.push(index);
  await render(
    `<CanonSegmented :items="modes" :selected="0" :on-change="pick" />`,
    { CanonSegmented, modes, pick },
  );
  expect(findAll('[role=radio]')).toHaveLength(3);
  await click('[role=radio]:nth-child(2)');
  expect(picks).toEqual([1]);
  expect(find('[role=radio]:nth-child(2)')).toHaveAttribute(
    'aria-checked',
    'true',
  );
  expect(find('[role=radio]:nth-child(1)')).toHaveAttribute(
    'aria-checked',
    'false',
  );
  await click('[role=radio]:nth-child(2)');
  expect(picks, 'the selected choice sends nothing').toEqual([1]);
});

test('greys single choices and shows symbols', async () => {
  await render(
    `<CanonSegmented :items="modes" :icons="icons" :disabled-indices="off" />`,
    { CanonSegmented, modes, icons: [Dot, Dot, Dot], off: [2] },
  );
  expect(find('[role=radio]:nth-child(3)')).toBeDisabled();
  expect(find('[role=radio]:nth-child(1)')).not.toBeDisabled();
  expect(find('[role=radio]:nth-child(1)')).toHaveAttribute(
    'aria-label',
    'Region',
  );
});
