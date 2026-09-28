import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonButton from '../src/components/canon-button.svelte';
import { click, dot, find, triggerEvent, wait } from './helpers.ts';

describe('canon-button', () => {
  test('kinds set their heights and fill', () => {
    render(CanonButton, { class: 'primary', text: 'Go', kind: 'primary' });
    render(CanonButton, { class: 'secondary', text: 'Go' });
    render(CanonButton, { class: 'cell', text: 'Go', kind: 'cell' });
    render(CanonButton, {
      class: 'segment',
      text: 'Go',
      kind: 'segment',
      selected: true,
    });
    const height = (s: string) => find(s).offsetHeight;
    expect(height('.primary')).toBe(68);
    expect(height('.secondary')).toBe(60);
    expect(height('.cell')).toBe(44);
    expect(find('.primary').classList).toContain('canon-button--filled');
    expect(find('.segment').classList).toContain('canon-button--filled');
    expect(find('.cell').classList).not.toContain('canon-button--filled');
  });

  test('runs onClick unless disabled', async () => {
    let clicks = 0;
    const count = () => (clicks += 1);
    render(CanonButton, { class: 'on', text: 'Go', onClick: count });
    render(CanonButton, {
      class: 'off',
      text: 'Go',
      onClick: count,
      disabled: true,
    });
    await click('.on');
    await click('.off').catch(() => undefined);
    expect(clicks).toBe(1);
  });

  test('an icon-only button is named by its label', () => {
    render(CanonButton, { kind: 'cell', icon: dot, label: 'Zoom in' });
    expect(find('button').getAttribute('aria-label')).toBe('Zoom in');
    expect(find('button').classList).toContain('canon-button--symbol');
    expect(document.querySelector('.canon-button-title')).toBeNull();
  });

  test('oversized draws the icon behind the title', () => {
    render(CanonButton, { text: 'Wipe', icon: dot, iconStyle: 'oversized' });
    expect(
      document.querySelector('.canon-button-watermark svg'),
    ).not.toBeNull();
    expect(document.querySelector('.canon-button-icon')).toBeNull();
    expect(find('.canon-button-title').textContent).toBe('Wipe');
  });

  test('flashesCopied shows Copied after a click', async () => {
    render(CanonButton, { text: 'Copy', icon: dot, flashesCopied: true });
    await click('button');
    expect(find('.canon-button-title').textContent).toBe('Copied');
  });

  test('repeats while held; the release does not add a step', async () => {
    let steps = 0;
    const step = () => (steps += 1);
    render(CanonButton, { text: '+', repeats: true, onClick: step });
    await triggerEvent('button', 'pointerdown', { button: 0 });
    await wait(600);
    await triggerEvent('button', 'pointerup', { button: 0 });
    const held = steps;
    await click('button');
    expect(held).toBeGreaterThanOrEqual(2);
    expect(steps).toBe(held);
    await click('button');
    expect(steps).toBe(held + 1);
  });
});
