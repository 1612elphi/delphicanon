import { describe, expect, test } from 'vitest';
import CanonDualList from '../../src/components/canon-dual-list.tsx';
import { click, find, findAll, render } from '../helpers/render.tsx';

const hidden = [{ id: 'b', name: 'Beta', caption: 'two' }];
const shown = [
  { id: 'a', name: 'Alpha' },
  { id: 'c', name: 'Gamma' },
];

describe('canon-dual-list', () => {
  test('one selection between two lists drives the actions', async () => {
    const calls: string[] = [];
    const right = (id: string) => calls.push(`right ${id}`);
    const reorder = (id: string, delta: number) =>
      calls.push(`reorder ${id} ${delta}`);
    await render(
      <CanonDualList
        left={hidden}
        right={shown}
        leftTitle="Hidden"
        rightTitle="Shown"
        listHeight={140}
        onMoveRight={right}
        onReorder={reorder}
      />,
    );
    const button = (text: string) =>
      findAll<HTMLButtonElement>('.canon-grid button').find(
        (b) => b.textContent?.trim() === text,
      )!;
    expect(findAll('.canon-dual-list-items')).toHaveLength(2);
    expect(find('.canon-dual-list-items').offsetHeight).toBe(140);
    expect(button('Show').disabled).toBe(true);

    await click('.canon-dual-list-item');
    expect(find('.canon-dual-list-item').getAttribute('aria-pressed')).toBe(
      'true',
    );
    expect(button('Show').disabled).toBe(false);
    expect(button('Up').disabled).toBe(true);
    await click(button('Show'));

    const gamma = findAll('.canon-dual-list-item')[2]!;
    await click(gamma);
    expect(button('Up').disabled).toBe(false);
    expect(button('Down').disabled).toBe(true);
    await click(button('Up'));
    expect(calls).toEqual(['right b', 'reorder c -1']);
  });
});
