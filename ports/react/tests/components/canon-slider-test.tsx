import { describe, expect, test } from 'vitest';
import CanonSlider from '../../src/components/canon-slider.tsx';
import { find, key, render, trigger } from '../helpers/render.tsx';

const whole = (value: number) => String(Math.round(value));

describe('canon-slider', () => {
  test('shows the readout and steps from the keyboard', async () => {
    const values: number[] = [];
    const record = (value: number) => values.push(value);
    await render(
      <CanonSlider
        value={99.4}
        min={1}
        max={100}
        step={1}
        readout={whole}
        label="Level"
        onChange={record}
      />,
    );
    expect(find('.canon-slider').getAttribute('role')).toBe('slider');
    expect(find('.canon-slider-readout').textContent).toBe('99');
    await key('.canon-slider', 'ArrowRight');
    await key('.canon-slider', 'ArrowRight');
    expect(values, 'stops at the top').toEqual([100]);
    await key('.canon-slider', 'Home');
    expect(find('.canon-slider').getAttribute('aria-valuenow')).toBe('1');
  });

  test('a tap on the track sets the value', async () => {
    await render(
      <div style={{ width: 300 }}>
        <CanonSlider value={0.2} label="Mix" />
      </div>,
    );
    const track = find('.canon-slider-track').getBoundingClientRect();
    const at = {
      button: 0,
      pointerId: 1,
      clientX: track.left + track.width * 0.75,
      clientY: track.top + track.height / 2,
    };
    await trigger('.canon-slider', 'pointerdown', at);
    await trigger('.canon-slider', 'pointerup', at);
    expect(find('.canon-slider-readout').textContent).toBe('75%');
  });

  test('a new range clamps the value', async () => {
    await render(<CanonSlider value={8} max={5} label="Gain" />);
    expect(find('.canon-slider').getAttribute('aria-valuenow')).toBe('5');
  });
});
