import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonPageStrip from '../src/components/canon-page-strip.svelte';
import State from './fixtures/canon-page-strip-state.svelte';
import { click, find, findAll, settled, triggerKeyEvent } from './helpers.ts';

const text = (selector: string) =>
  find(selector).textContent.replace(/\s+/g, ' ').trim();

describe('canon-page-strip', () => {
  test('pages to scale, lit, stacked, reordered by keyboard', async () => {
    const moves: [number, number][] = [];
    let selected = 1;
    await render(State, {
      onMove: (from, to) => moves.push([from, to]),
      onSelect: (index) => (selected = index),
    });
    const papers = findAll('.canon-page-strip-stack');
    expect(papers).toHaveLength(3);
    const [portrait, landscape] = papers.map((p) => p.getBoundingClientRect());
    // portrait is tall, landscape is wide
    expect(portrait!.height).toBeGreaterThan(portrait!.width);
    expect(landscape!.width).toBeGreaterThan(landscape!.height);
    expect(text('.canon-page-strip-cell--lit')).toBe('2 B');
    expect(findAll('.canon-page-strip-sheet')).toHaveLength(2);

    await click('[data-page-index="0"] .canon-page-strip-page');
    expect(selected).toBe(0);
    expect(
      find('[data-page-index="0"] button').getAttribute('aria-current'),
    ).toBe('true');

    await triggerKeyEvent(
      '[data-page-index="0"] button',
      'keydown',
      'ArrowRight',
      { altKey: true },
    );
    await settled();
    expect(moves).toEqual([[0, 1]]);
    expect(text('[data-page-index="1"] .canon-page-strip-name')).toBe('A');
  });

  test('no pages shows the empty text', async () => {
    await render(CanonPageStrip, { pages: [] });
    expect(text('.canon-page-strip-empty')).toBe('Pages');
  });
});
