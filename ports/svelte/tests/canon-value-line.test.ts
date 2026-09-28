import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonValueLine from '../src/components/canon-value-line.svelte';
import { canonToast } from '../src/lib/toast-store.svelte.ts';
import Layouts from './fixtures/canon-value-line-layouts.svelte';
import { click, fakeClipboard, find, findAll } from './helpers.ts';

test('shows the label and value and copies the value', async () => {
  const written = fakeClipboard(canonToast);
  await render(CanonValueLine, {
    label: 'OKLCH',
    value: 'oklch(0.5 0.1 140)',
    labelWidth: 60,
  });
  expect(find('.canon-value-line-label').textContent).toBe('OKLCH');
  expect(find('.canon-value-line-value').textContent).toBe(
    'oklch(0.5 0.1 140)',
  );
  expect(find('.canon-value-line-label').offsetWidth).toBe(60);
  await click('.canon-value-line');
  expect(written).toEqual(['oklch(0.5 0.1 140)']);
});

test('a missing value shows a dash and turns copying off', async () => {
  await render(CanonValueLine, { label: 'Nil', value: null });
  expect(find('.canon-value-line-value').textContent).toBe('—');
  expect(find<HTMLButtonElement>('.canon-value-line').disabled).toBe(true);
});

test('layouts, lit and tint', async () => {
  await render(Layouts);
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
