import { describe, expect, test } from 'vitest';
import CanonDimensionLine from '../../src/components/canon-dimension-line.tsx';
import { find, render } from '../helpers/render.tsx';

describe('canon-dimension-line', () => {
  test('a rule with ticks and the figure, turned or blank', async () => {
    await render(
      <div style={{ position: 'relative', width: 400, height: 300 }}>
        <CanonDimensionLine
          className="across"
          pixels={1600}
          style={{ insetInlineStart: 44, insetBlockStart: 0, inlineSize: 200 }}
        />
        <CanonDimensionLine className="down" pixels={1200} down />
        <CanonDimensionLine className="blank" pixels={1600} blank />
      </div>,
    );
    expect(find('.across').getAttribute('aria-hidden')).toBe('true');
    expect(find('.across .canon-figure-said').textContent).toBe('1600px');
    expect(find('.across').offsetWidth).toBe(200);
    expect(find('.across').offsetHeight).toBe(32);
    expect(getComputedStyle(find('.down')).rotate).toBe('-90deg');
    expect(document.querySelector('.blank .canon-figure')).toBeNull();
    const ink = (selector: string) =>
      getComputedStyle(find(selector), '::before').backgroundColor;
    expect(ink('.blank'), 'blank ticks are muted').not.toBe(ink('.across'));
  });
});
