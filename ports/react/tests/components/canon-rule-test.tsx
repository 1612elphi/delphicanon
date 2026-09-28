import { describe, expect, test } from 'vitest';
import CanonRule from '../../src/components/canon-rule.tsx';
import { findAll, render } from '../helpers/render.tsx';

describe('canon-rule', () => {
  test('draws a hairline either way', async () => {
    await render(
      <>
        <div style={{ display: 'flex', height: 40 }}>
          <CanonRule vertical />
        </div>
        <CanonRule />
      </>,
    );
    const [vertical, horizontal] = findAll('.canon-rule');
    expect(vertical?.offsetWidth).toBe(1);
    expect(vertical?.offsetHeight).toBe(40);
    expect(horizontal?.offsetHeight).toBe(1);
    expect(vertical?.getAttribute('aria-orientation')).toBe('vertical');
  });
});
