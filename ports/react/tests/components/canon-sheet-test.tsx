import { useState } from 'react';
import { describe, expect, test } from 'vitest';
import CanonSheet, {
  type CanonSheetEdge,
} from '../../src/components/canon-sheet.tsx';
import { click, find, render, settle, waitUntil } from '../helpers/render.tsx';

const closes: string[] = [];

function Owner() {
  const [open, setOpen] = useState(true);
  const [edge, setEdge] = useState<CanonSheetEdge>('end');
  return (
    <>
      <button
        type="button"
        id="bottom"
        onClick={() => {
          setEdge('bottom');
          setOpen(true);
        }}
      >
        Bottom
      </button>
      <CanonSheet
        open={open}
        edge={edge}
        title="Sheet"
        onClose={(value) => {
          closes.push(value);
          setOpen(false);
        }}
      >
        <p>Body</p>
      </CanonSheet>
    </>
  );
}

describe('canon-sheet', () => {
  test('a modal dialog on an edge of the window', async () => {
    await render(<Owner />);
    const sheet = find<HTMLDialogElement>('dialog');
    expect(sheet.matches(':modal')).toBe(true);
    expect(sheet.classList.contains('canon-dialog')).toBe(true);
    expect(sheet.classList.contains('canon-sheet--end')).toBe(true);
    await waitUntil(() => sheet.getAnimations().length === 0);
    const box = sheet.getBoundingClientRect();
    expect(Math.round(box.right), 'meets the end edge').toBe(
      document.documentElement.clientWidth,
    );
    expect(Math.round(box.height)).toBe(window.innerHeight);

    await settle(() =>
      sheet.dispatchEvent(new Event('cancel', { cancelable: true })),
    );
    await waitUntil(() => !sheet.open);
    await settle();
    expect(closes, 'Escape closes it').toEqual(['']);

    await click('#bottom');
    expect(sheet.classList.contains('canon-sheet--bottom')).toBe(true);
    await waitUntil(() => sheet.getAnimations().length === 0);
    expect(
      Math.round(sheet.getBoundingClientRect().bottom),
      'meets the bottom edge',
    ).toBe(window.innerHeight);
  });
});
