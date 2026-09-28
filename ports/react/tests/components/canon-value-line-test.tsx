import { describe, expect, test } from 'vitest';
import CanonValueLine from '../../src/components/canon-value-line.tsx';
import { fakeClipboard } from '../helpers/clipboard.ts';
import { click, find, findAll, render } from '../helpers/render.tsx';

const digitsGreen = (character: string) =>
  /\d/.test(character) ? 'rgb(0, 128, 0)' : 'rgb(0, 0, 0)';

describe('canon-value-line', () => {
  test('shows the label and value and copies the value', async () => {
    const written = fakeClipboard();
    await render(
      <CanonValueLine
        label="OKLCH"
        value="oklch(0.5 0.1 140)"
        labelWidth={60}
      />,
    );
    expect(find('.canon-value-line-label').textContent).toBe('OKLCH');
    expect(find('.canon-value-line-value').textContent).toBe(
      'oklch(0.5 0.1 140)',
    );
    expect(find('.canon-value-line-label').offsetWidth).toBe(60);
    await click('.canon-value-line');
    expect(written).toEqual(['oklch(0.5 0.1 140)']);
  });

  test('a missing value shows a dash and turns copying off', async () => {
    await render(<CanonValueLine label="Nil" value={null} />);
    expect(find('.canon-value-line-value').textContent).toBe('—');
    expect(find<HTMLButtonElement>('.canon-value-line').disabled).toBe(true);
  });

  test('layouts, lit and tint', async () => {
    await render(
      <div style={{ width: 240 }}>
        <CanonValueLine
          className="above"
          label="Above"
          value="#1e6626"
          layout="above"
        />
        <CanonValueLine
          className="wrapping"
          label="x ="
          value="#1e6626#1e6626#1e6626#1e6626"
          layout="wrapping"
        />
        <CanonValueLine
          className="numbered"
          label="01"
          value="#1e6626"
          layout="numbered"
          lit
          tint={digitsGreen}
        />
      </div>,
    );
    const box = (selector: string) => find(selector).getBoundingClientRect();
    // value under the label
    expect(box('.above .canon-value-line-value').top).toBeGreaterThan(
      box('.above .canon-value-line-label').bottom - 1,
    );
    // the long value wraps
    expect(box('.wrapping .canon-value-line-value').height).toBeGreaterThan(
      box('.wrapping .canon-value-line-label').height * 1.5,
    );
    const numbered = find('.numbered');
    expect(numbered.getAttribute('aria-label')).toBe('#1e6626');
    expect(numbered.getAttribute('aria-current')).toBe('true');
    expect(numbered.classList).toContain('canon-value-line--lit');
    const characters = findAll('.numbered .canon-value-line-value span');
    expect(characters.length).toBe(7);
    expect(characters[1]!.style.color).toBe('rgb(0, 128, 0)');
    expect(characters[2]!.style.color).toBe('rgb(0, 0, 0)');
  });
});
