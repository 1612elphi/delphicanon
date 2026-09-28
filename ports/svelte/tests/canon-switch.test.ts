import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonSwitch from '../src/components/canon-switch.svelte';
import { click, find } from './helpers.ts';

test('a native switch that reports each flip', async () => {
  const flips: boolean[] = [];
  await render(CanonSwitch, {
    on: true,
    'aria-label': 'Sound',
    onChange: (on) => flips.push(on),
  });
  const input = find<HTMLInputElement>('input');
  expect(input.getAttribute('role')).toBe('switch');
  expect(input.checked).toBe(true);
  expect(input.getAttribute('aria-checked')).toBe('true');
  await click('input');
  await click('input');
  expect(flips).toEqual([false, true]);
  expect(input.getAttribute('aria-checked')).toBe('true');
});
