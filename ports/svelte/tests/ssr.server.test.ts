import { render } from 'svelte/server';
import { describe, expect, test } from 'vitest';
import CanonCommand from '../src/components/canon-command.svelte';
import CanonCompressionScale from '../src/components/canon-compression-scale.svelte';
import CanonContextMenu from '../src/components/canon-context-menu.svelte';
import CanonDialog from '../src/components/canon-dialog.svelte';
import CanonDimensionLine from '../src/components/canon-dimension-line.svelte';
import CanonJumpGrid from '../src/components/canon-jump-grid.svelte';
import CanonJumpHeading from '../src/components/canon-jump-heading.svelte';
import CanonMenuBar from '../src/components/canon-menu-bar.svelte';
import CanonMenu, {
  type CanonMenuEntry,
} from '../src/components/canon-menu.svelte';
import CanonPopover from '../src/components/canon-popover.svelte';
import CanonSheet from '../src/components/canon-sheet.svelte';
import CanonSidebarRow from '../src/components/canon-sidebar-row.svelte';
import CanonSidebar from '../src/components/canon-sidebar.svelte';
import CanonTooltip from '../src/components/canon-tooltip.svelte';
import CanonWindow from '../src/components/canon-window.svelte';
import { check, iconSnippet } from '../src/lib/control-icons.ts';

const icon = iconSnippet(check);
const items: CanonMenuEntry[] = [
  { title: 'Copy', icon, shortcut: '⌘C' },
  { title: 'Share', items: [{ title: 'Email' }] },
  { kind: 'separator' },
  { title: 'Grid', kind: 'checkbox', checked: true },
];

const cases: [string, () => { body: string }][] = [
  [
    'canon-popover',
    () => render(CanonPopover, { props: { placement: 'top' } }),
  ],
  ['canon-tooltip', () => render(CanonTooltip, { props: { text: 'Copy' } })],
  ['canon-menu', () => render(CanonMenu, { props: { items } })],
  ['canon-context-menu', () => render(CanonContextMenu, { props: { items } })],
  [
    'canon-menu-bar',
    () =>
      render(CanonMenuBar, { props: { menus: [{ title: 'File', items }] } }),
  ],
  ['canon-sidebar', () => render(CanonSidebar, { props: { collapsed: true } })],
  [
    'canon-sidebar-row',
    () =>
      render(CanonSidebarRow, {
        props: { title: 'Toolbox', href: '#', icon },
      }),
  ],
  [
    'canon-window',
    () =>
      render(CanonWindow, { props: { title: 'Delphi', onClose: () => {} } }),
  ],
  [
    'canon-dialog',
    () =>
      render(CanonDialog, { props: { open: true, title: 'T', message: 'M' } }),
  ],
  [
    'canon-sheet',
    () =>
      render(CanonSheet, { props: { open: true, edge: 'end', title: 'T' } }),
  ],
  [
    'canon-jump-heading',
    () => render(CanonJumpHeading, { props: { text: 'Rows', detail: '2' } }),
  ],
  [
    'canon-jump-grid',
    () =>
      render(CanonJumpGrid, {
        props: { open: true, sections: [{ title: 'Rows' }], current: 0 },
      }),
  ],
  [
    'canon-command',
    () =>
      render(CanonCommand, {
        props: {
          items: [{ id: 'a', title: 'A', group: 'G', icon, shortcut: ['⌘'] }],
        },
      }),
  ],
  [
    'canon-compression-scale',
    () =>
      render(CanonCompressionScale, {
        props: { before: 2000, after: 1000, format: 'JPEG', working: true },
      }),
  ],
  [
    'canon-dimension-line',
    () => render(CanonDimensionLine, { props: { pixels: 1080, down: true } }),
  ],
];

describe('server render', () => {
  test.each(cases)('%s renders without a DOM', (name, renderOnServer) => {
    expect(renderOnServer().body).toContain(name);
  });
});
