import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonLoader from '../src/components/canon-loader.svelte';
import { find, findAll } from './helpers.ts';

test('nine cells sized by cell and gap', async () => {
  await render(CanonLoader, { class: 'big' });
  await render(CanonLoader, {
    class: 'small',
    mode: 'thinking',
    cell: 4,
    gap: 1,
  });
  expect(findAll('.big > *').length).toBe(9);
  expect(find('.big').getAttribute('role')).toBe('status');
  expect(find('.big').getAttribute('aria-label')).toBe('Loading');
  expect(find('.small').classList).toContain('canon-loader--thinking');
  expect(find('.big').offsetWidth).toBe(28);
  expect(find('.small').offsetWidth).toBe(14);
});
