import { expect, test } from 'vitest';
import CanonValueLine from '../../src/components/canon-value-line.vue';
import { fakeClipboard } from '../helpers/fake-clipboard.ts';
import { click, find, findAll, render } from '../helpers/render.ts';

const digitsGreen = (character: string) =>
  /\d/.test(character) ? 'rgb(0, 128, 0)' : 'rgb(0, 0, 0)';

test('shows the label and value and copies the value', async () => {
  const written = fakeClipboard();
  await render(
    `<CanonValueLine label="OKLCH" value="oklch(0.5 0.1 140)" :label-width="60" />`,
    { CanonValueLine },
  );
  expect(find('.canon-value-line-label').textContent?.trim()).toBe('OKLCH');
  expect(find('.canon-value-line-value').textContent?.trim()).toBe(
    'oklch(0.5 0.1 140)',
  );
  expect(find('.canon-value-line-label').offsetWidth).toBe(60);
  await click('.canon-value-line');
  expect(written).toEqual(['oklch(0.5 0.1 140)']);
});

test('a missing value shows a dash and turns copying off', async () => {
  await render(`<CanonValueLine label="Nil" :value="null" />`, {
    CanonValueLine,
  });
  expect(find('.canon-value-line-value').textContent?.trim()).toBe('—');
  expect(find('.canon-value-line')).toBeDisabled();
});

test('layouts, lit and tint', async () => {
  await render(
    `<div style="width: 240px">
      <CanonValueLine class="above" label="Above" value="#1e6626" layout="above" />
      <CanonValueLine
        class="wrapping"
        label="x ="
        value="#1e6626#1e6626#1e6626#1e6626"
        layout="wrapping"
      />
      <CanonValueLine
        class="numbered"
        label="01"
        value="#1e6626"
        layout="numbered"
        :lit="true"
        :tint="digitsGreen"
      />
    </div>`,
    { CanonValueLine, digitsGreen },
  );
  const box = (selector: string) => find(selector).getBoundingClientRect();
  expect(
    box('.above .canon-value-line-value').top >
      box('.above .canon-value-line-label').bottom - 1,
    'value under the label',
  ).toBe(true);
  expect(
    box('.wrapping .canon-value-line-value').height >
      box('.wrapping .canon-value-line-label').height * 1.5,
    'the long value wraps',
  ).toBe(true);
  expect(find('.numbered')).toHaveAttribute('aria-label', '#1e6626');
  expect(find('.numbered')).toHaveAttribute('aria-current', 'true');
  expect(find('.numbered')).toHaveClass('canon-value-line--lit');
  const characters = findAll('.numbered .canon-value-line-value span');
  expect(characters).toHaveLength(7);
  expect(characters[1]!.style.color).toBe('rgb(0, 128, 0)');
  expect(characters[2]!.style.color).toBe('rgb(0, 0, 0)');
});
