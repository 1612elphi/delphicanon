import { describe, expect, test } from 'vitest';
import CanonCompressionScale from '../../src/components/canon-compression-scale.tsx';
import { find, findAll, render } from '../helpers/render.tsx';

const said = () => find('.canon-figure-said').textContent;
const bars = () => findAll('.canon-compression-scale-bar');
const text = (element: Element | undefined) =>
  element?.textContent?.replace(/\s+/g, ' ').trim();

describe('canon-compression-scale', () => {
  test('the original over the result, the saving as a figure', async () => {
    const scale = (before: number, after: number, working = false) => (
      <div style={{ width: 600, height: 176 }}>
        <CanonCompressionScale
          before={before}
          after={after}
          format="JPEG"
          working={working}
        />
      </div>
    );
    const { rerender } = await render(scale(0, 0));
    expect(said(), 'a dash before a result').toBe('—');
    expect(text(bars()[0])).toBe('Original');
    expect(document.querySelector('.canon-loader')).toBeNull();

    await rerender(scale(2_400_000, 0, true));
    expect(document.querySelector('.canon-loader')).not.toBeNull();
    expect(text(bars()[0])).toBe('Original 2.3 MB');
    expect(text(bars()[1])).toBe('JPEG');

    await rerender(scale(2_400_000, 1_200_000));
    expect(said()).toBe('−50%');
    expect(text(bars()[1])).toBe('JPEG 1.1 MB');
    expect(bars()[1]!.hasAttribute('data-inside')).toBe(true);
    expect(
      bars()[1]!.style.getPropertyValue('--canon-compression-scale-share'),
    ).toBe('0.5');

    await rerender(scale(2_400_000, 3_600_000));
    expect(said()).toBe('+50%');
    expect(
      find(bars()[1]!.querySelector('.canon-bar')!).style.getPropertyValue(
        '--canon-bar-fill',
      ),
      'red when the result grew',
    ).toBe('var(--canon-destructive)');

    await rerender(scale(2_400_000, 24_000));
    expect(
      bars()[1]!.hasAttribute('data-inside'),
      'a sliver puts the label after the fill',
    ).toBe(false);
  });
});
