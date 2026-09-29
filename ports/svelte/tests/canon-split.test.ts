import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Scenes from './fixtures/canon-split-scenes.svelte';
import { find, settled } from './helpers.ts';

const layout = () =>
  getComputedStyle(find('.canon-split-body'))
    .getPropertyValue('--canon-split-layout')
    .trim();
const frame = () => new Promise(requestAnimationFrame);
const box = (selector: string) => find(selector).getBoundingClientRect();

describe('canon-split', () => {
  test('wide: a 340 px sidebar beside the main pane, banner across both', async () => {
    await render(Scenes, { scene: 'wide' });
    expect(layout()).toBe('wide');
    expect(find('.canon-split-sidebar').offsetWidth).toBe(340);
    expect(find('.canon-split-main').offsetLeft).toBe(341);
    expect(find('.canon-split-banner').offsetWidth).toBe(1000);
    expect(find('.canon-split-main .canon-split-footer').textContent).toBe(
      'Strip',
    );
  });

  test('narrow or portrait: one column, sidebar first', async () => {
    await render(Scenes, { scene: 'narrow' });
    expect(layout()).toBe('stacked');
    expect(box('.main').top).toBeGreaterThan(box('.side').top);
    expect(box('.main').left).toBe(box('.side').left);
  });

  test('oneColumn stacks at every width', async () => {
    await render(Scenes, { scene: 'one-column' });
    expect(layout()).toBe('stacked');
    expect(box('.main').top).toBeGreaterThan(box('.side').top);
  });

  test('mainLeadsStacked and halves', async () => {
    await render(Scenes, { scene: 'leads-halves' });
    expect(box('.stacked .side').top).toBeGreaterThan(
      box('.stacked .main').top,
    );
    const picture = find('.halves .canon-split-sidebar .canon-canvas');
    expect(picture.offsetWidth).toBe(500);
    // the picture fills its pane
    expect(picture.offsetHeight).toBe(600);
  });

  test('a collapsing picture refits to a new aspect', async () => {
    const { rerender } = await render(Scenes, { scene: 'collapsing' });
    const split = find('.canon-split');
    const full = () => split.style.getPropertyValue('--canon-split-full');
    expect(split.hasAttribute('data-collapsing')).toBe(true);
    expect(full()).toBe('480px');
    // the ResizeObserver's first notification would refit on its own
    await frame();
    await frame();
    await rerender({ aspect: 2 });
    await settled();
    expect(full(), 'half the width and the frame').toBe('254px');
  });

  test('footerHidden takes the footer away', async () => {
    await render(Scenes, { scene: 'footer-hidden' });
    expect(document.querySelector('.canon-split-footer')).toBeNull();
  });
});
