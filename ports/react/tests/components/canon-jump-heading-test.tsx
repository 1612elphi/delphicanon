import { Fragment } from 'react';
import { describe, expect, test } from 'vitest';
import CanonJumpHeading from '../../src/components/canon-jump-heading.tsx';
import {
  click,
  find,
  findAll,
  render,
  settle,
  waitUntil,
} from '../helpers/render.tsx';

const groups = ['Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon'];

describe('canon-jump-heading', () => {
  test('opens a grid of its scrolling box’s groups lit at the one in view; a pick scrolls there and focuses it', async () => {
    await render(
      <div className="list" style={{ blockSize: 200, overflowY: 'auto' }}>
        {groups.map((group) => (
          <Fragment key={group}>
            <CanonJumpHeading text={group} detail="3" />
            <div style={{ blockSize: 300 }}></div>
          </Fragment>
        ))}
      </div>,
    );
    const list = find('.list');
    const headings = findAll('.canon-jump-heading');
    expect(headings[0]!.tagName, 'a heading').toBe('H3');
    const buttons = findAll('.canon-jump-heading-button');
    expect(buttons).toHaveLength(5);
    expect(buttons[0]!.getAttribute('aria-haspopup')).toBe('dialog');

    list.scrollTop = headings[2]!.offsetTop - list.offsetTop;
    // the helper focuses first, which would scroll an off-screen heading in
    await click(headings[2]!.querySelector('button')!);
    expect(findAll('.canon-jump-grid-tile')).toHaveLength(5);
    expect(find('.canon-jump-grid-tile--lit').textContent).toBe('Gamma3');

    await click('.canon-jump-grid-tile:nth-child(4)');
    const target = headings[3]!;
    await waitUntil(
      () =>
        !document.querySelector('dialog') &&
        Math.abs(
          target.getBoundingClientRect().top - list.getBoundingClientRect().top,
        ) < 2,
      3000,
    );
    await settle();
    expect(document.activeElement).toBe(target.querySelector('button'));
  });
});
