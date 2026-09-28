import { describe, expect, test } from 'vitest';
import CanonMathRail from '../../src/components/canon-math-rail.tsx';
import type { Key } from '@canon/lib/math/expression.ts';
import { click, render, trigger } from '../helpers/render.tsx';

describe('canon-math-rail', () => {
  test('the rail steps the caret with its arrows and its ribs', async () => {
    const steps: string[] = [];
    const step = (key: Key) => (steps.push(key.kind), true);
    await render(
      <div style={{ width: 400 }}>
        <CanonMathRail onStep={step} />
      </div>,
    );
    await click('[aria-label="Left"]');
    await click('[aria-label="Up"]');
    const ribs = '.canon-math-rail-ribs';
    await trigger(ribs, 'pointerdown', {
      button: 0,
      clientX: 100,
      pointerId: 1,
    });
    await trigger(ribs, 'pointermove', { clientX: 140, pointerId: 1 });
    await trigger(ribs, 'pointerup', { clientX: 140, pointerId: 1 });
    expect(steps).toEqual(['left', 'up', 'right', 'right']);
  });
});
