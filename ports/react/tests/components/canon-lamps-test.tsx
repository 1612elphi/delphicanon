import { describe, expect, test } from 'vitest';
import CanonLamps, {
  type CanonLamp,
} from '../../src/components/canon-lamps.tsx';
import { find, findAll, render } from '../helpers/render.tsx';

const lit: CanonLamp[] = ['play', 'loop'];
const recording: CanonLamp[] = ['record', 'pause'];

describe('canon-lamps', () => {
  test('every lamp present, lit ones lit, a flash blinks', async () => {
    const ui = (loops: number) => (
      <>
        <CanonLamps lit={lit} flashes={{ loop: loops }} />
        <CanonLamps className="rec" lamps={recording} lit={recording} />
      </>
    );
    const { rerender } = await render(ui(0));
    expect(findAll('.canon-lamps-lamp')).toHaveLength(5);
    expect(find('.canon-lamps-lamp--play').classList).toContain(
      'canon-lamps-lamp--lit',
    );
    expect(find('.canon-lamps-lamp--pause').classList).not.toContain(
      'canon-lamps-lamp--lit',
    );
    expect(document.querySelector('.canon-lamps-lamp--blink')).toBeNull();
    await rerender(ui(1));
    expect(find('.canon-lamps-lamp--loop').classList).toContain(
      'canon-lamps-lamp--blink',
    );
    expect(find('.rec .canon-lamps-lamp--record').classList).toContain(
      'canon-lamps-lamp--lit',
    );
  });
});
