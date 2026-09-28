import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonLamps, {
  type CanonLamp,
} from '../src/components/canon-lamps.svelte';
import { find, findAll, settled } from './helpers.ts';

const recording: CanonLamp[] = ['record', 'pause'];

describe('canon-lamps', () => {
  test('every lamp present, lit ones lit, a flash blinks', async () => {
    const lit: CanonLamp[] = ['play', 'loop'];
    const { rerender } = await render(CanonLamps, {
      lit,
      flashes: { loop: 0 },
    });
    await render(CanonLamps, {
      class: 'rec',
      lamps: recording,
      lit: recording,
    });
    expect(findAll('.canon-lamps-lamp')).toHaveLength(5);
    expect(find('.canon-lamps-lamp--play').classList).toContain(
      'canon-lamps-lamp--lit',
    );
    expect(find('.canon-lamps-lamp--pause').classList).not.toContain(
      'canon-lamps-lamp--lit',
    );
    expect(document.querySelector('.canon-lamps-lamp--blink')).toBeNull();
    await rerender({ flashes: { loop: 1 } });
    await settled();
    expect(find('.canon-lamps-lamp--loop').classList).toContain(
      'canon-lamps-lamp--blink',
    );
    expect(find('.rec .canon-lamps-lamp--record').classList).toContain(
      'canon-lamps-lamp--lit',
    );
  });
});
