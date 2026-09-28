import { describe, expect, test } from 'vitest';
import CanonBar from '../../src/components/canon-bar.tsx';
import { find, render } from '../helpers/render.tsx';

describe('canon-bar', () => {
  test('fills its share of the width, clamped', async () => {
    await render(
      <div style={{ width: 200 }}>
        <CanonBar className="quarter" share={0.25} />
        <CanonBar className="over" share={2} />
      </div>,
    );
    const fill = (selector: string) =>
      find(`${selector} .canon-bar-fill`).offsetWidth;
    expect(fill('.quarter')).toBe(50);
    expect(fill('.over')).toBe(200);
  });
});
