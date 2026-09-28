import { describe, expect, test } from 'vitest';
import CanonMenuCell from '../../src/components/canon-menu-cell.tsx';
import { find, render, select } from '../helpers/render.tsx';

const items = ['One', 'Two', 'Three'];

describe('canon-menu-cell', () => {
  test('shows the choice and reports a new one', async () => {
    const picks: number[] = [];
    const record = (index: number) => picks.push(index);
    await render(
      <CanonMenuCell
        items={items}
        selected={0}
        label="Count"
        onChange={record}
      />,
    );
    expect(find('.canon-menu-cell-title').textContent).toBe('One');
    expect(find('select').getAttribute('aria-label')).toBe('Count');
    await select('select', '2');
    expect(picks).toEqual([2]);
    expect(find('.canon-menu-cell-title').textContent).toBe('Three');
    expect(find('.canon-menu-cell').offsetHeight).toBe(44);
  });

  test('no selection shows the placeholder', async () => {
    await render(<CanonMenuCell items={items} label="Count" />);
    expect(find('.canon-menu-cell-title').textContent).toBe('—');
    expect(document.querySelector('option[hidden]')).not.toBeNull();
  });
});
