import { expect, test } from 'vitest';
import CanonCommand, {
  type CanonCommandItem,
} from '../../src/components/canon-command.vue';
import Dot from '../helpers/dot.ts';
import {
  click,
  fillIn,
  find,
  findAll,
  render,
  triggerEvent,
  triggerKeyEvent,
} from '../helpers/render.ts';

const items: CanonCommandItem[] = [
  { id: 'contrast', title: 'Contrast checker', group: 'Colour', icon: Dot },
  { id: 'shades', title: 'Tailwind shades', group: 'Colour' },
  { id: 'count', title: 'Word counter', group: 'Text', keywords: ['length'] },
  { id: 'paste', title: 'Paste', group: 'Text', disabled: true },
  { id: 'copy', title: 'Copy', group: 'Text', shortcut: ['⌘', 'C'] },
];

const activeTitle = () => {
  const id = find('.canon-command-input').getAttribute('aria-activedescendant');
  return id
    ? document.getElementById(id)!.querySelector('.canon-command-title')!
        .textContent
    : null;
};

test('a combobox over grouped options, filtered and ranked', async () => {
  const queries: string[] = [];
  const query = (text: string) => queries.push(text);
  await render(
    `<CanonCommand :items="items" placeholder="Search tools" :on-query="query" />`,
    { CanonCommand, items, query },
  );
  const input = find('.canon-command-input');
  expect(input).toHaveAttribute('role', 'combobox');
  expect(input).toHaveAttribute('aria-expanded', 'true');
  expect(input).toHaveAttribute('aria-controls', find('[role=listbox]').id);
  expect(findAll('[role=group]')).toHaveLength(2);
  expect(findAll('[role=option]')).toHaveLength(5);
  expect(find('.canon-heading')).toHaveTextContent('Colour');
  expect(findAll('.canon-command-icon svg')).toHaveLength(1);
  expect(findAll('.canon-command-key')).toHaveLength(2);
  expect(find('[aria-disabled=true]')).toHaveTextContent('Paste');
  expect(activeTitle()).toBe('Contrast checker');

  await fillIn('.canon-command-input', 'len');
  expect(queries).toEqual(['len']);
  expect(findAll('[role=option]'), 'a keyword matches').toHaveLength(1);
  expect(activeTitle()).toBe('Word counter');

  await fillIn('.canon-command-input', 'zzz');
  expect(findAll('[role=option]')).toHaveLength(0);
  expect(find('.canon-command-empty')).toHaveTextContent('No results');
  expect(input).not.toHaveAttribute('aria-activedescendant');
});

test('the arrow keys wrap past disabled rows; Enter and a click select', async () => {
  const picked: string[] = [];
  const select = (item: CanonCommandItem) => picked.push(item.id);
  await render(`<CanonCommand :items="items" :on-select="select" />`, {
    CanonCommand,
    items,
    select,
  });
  const input = '.canon-command-input';
  await triggerKeyEvent(input, 'keydown', 'ArrowUp');
  expect(activeTitle(), 'wraps to the last row').toBe('Copy');
  await triggerKeyEvent(input, 'keydown', 'ArrowUp');
  expect(activeTitle(), 'skips Paste').toBe('Word counter');
  await triggerKeyEvent(input, 'keydown', 'Enter');
  expect(picked).toEqual(['count']);

  await triggerEvent('[role=option]:nth-of-type(2)', 'pointermove');
  expect(activeTitle(), 'the pointer moves it').toBe('Tailwind shades');
  await click('[aria-disabled=true]');
  expect(picked, 'a disabled row does nothing').toEqual(['count']);
  await click('[role=option]');
  expect(picked).toEqual(['count', 'contrast']);

  await fillIn(input, 'cop');
  await triggerKeyEvent(input, 'keydown', 'Escape');
  expect(find<HTMLInputElement>(input), 'Escape clears the query').toHaveValue(
    '',
  );
  expect(findAll('[role=option]')).toHaveLength(5);
});
