<script lang="ts" module>
  export const pane = 'main';
  export const order = 8;
</script>

<script lang="ts">
  import type { Attachment } from 'svelte/attachments';
  import CanonButton from '../../src/components/canon-button.svelte';
  import CanonCommand, {
    type CanonCommandItem,
  } from '../../src/components/canon-command.svelte';
  import CanonDialog, {
    type CanonDialogClose,
  } from '../../src/components/canon-dialog.svelte';
  import CanonGrid from '../../src/components/canon-grid.svelte';
  import CanonHeading from '../../src/components/canon-heading.svelte';
  import CanonRow from '../../src/components/canon-row.svelte';
  import CanonRows from '../../src/components/canon-rows.svelte';
  import CanonSegmented from '../../src/components/canon-segmented.svelte';
  import CanonSheet, {
    type CanonSheetEdge,
  } from '../../src/components/canon-sheet.svelte';
  import CanonSwitch from '../../src/components/canon-switch.svelte';
  import { icon } from '../icon.ts';
  import blend from 'lucide-static/icons/blend.svg?raw';
  import caseSensitive from 'lucide-static/icons/case-sensitive.svg?raw';
  import clipboardPaste from 'lucide-static/icons/clipboard-paste.svg?raw';
  import command from 'lucide-static/icons/command.svg?raw';
  import contrast from 'lucide-static/icons/contrast.svg?raw';
  import copy from 'lucide-static/icons/copy.svg?raw';
  import hashSvg from 'lucide-static/icons/hash.svg?raw';
  import palette from 'lucide-static/icons/palette.svg?raw';
  import panelBottom from 'lucide-static/icons/panel-bottom.svg?raw';
  import panelLeft from 'lucide-static/icons/panel-left.svg?raw';
  import panelRight from 'lucide-static/icons/panel-right.svg?raw';
  import panelTop from 'lucide-static/icons/panel-top.svg?raw';
  import ruler from 'lucide-static/icons/ruler.svg?raw';
  import text from 'lucide-static/icons/text.svg?raw';
  import trash from 'lucide-static/icons/trash-2.svg?raw';

  // ∑CG: gallery, the message of the export dialog under its title
  //   spec: one sentence saying the palette is saved as a file in the chosen format; up to 90 chars, plain, sentence case
  //   sample: "The palette is saved as one file in the format you pick."
  const exportMessage = '∑CG';

  // ∑CG: gallery, the message of the delete alert under its title
  //   spec: one sentence warning that deleting the palette cannot be undone; up to 70 chars, plain, sentence case
  //   sample: "This palette and its swatches go for good."
  const deleteMessage = '∑CG';

  const items: CanonCommandItem[] = [
    {
      id: 'contrast',
      title: 'Contrast checker',
      group: 'Colour',
      keywords: ['wcag', 'apca'],
      icon: icon(contrast),
    },
    {
      id: 'shades',
      title: 'Tailwind shades',
      group: 'Colour',
      keywords: ['palette', 'scale'],
      icon: icon(palette),
    },
    {
      id: 'harmony',
      title: 'Harmony genny',
      group: 'Colour',
      keywords: ['complementary', 'triad'],
      icon: icon(blend),
    },
    {
      id: 'case',
      title: 'Case converter',
      group: 'Text',
      keywords: ['upper', 'lower', 'title'],
      icon: icon(caseSensitive),
    },
    {
      id: 'count',
      title: 'Word counter',
      group: 'Text',
      detail: 'Text › Analysis',
      icon: icon(text),
    },
    {
      id: 'hash',
      title: 'Hash generator',
      group: 'Text',
      keywords: ['sha', 'md5'],
      icon: icon(hashSvg),
    },
    {
      id: 'copy',
      title: 'Copy',
      group: 'Actions',
      shortcut: ['⌘', 'C'],
      icon: icon(copy),
    },
    {
      id: 'paste',
      title: 'Paste',
      group: 'Actions',
      shortcut: ['⌘', 'V'],
      disabled: true,
      icon: icon(clipboardPaste),
    },
    {
      id: 'delete',
      title: 'Delete palette',
      group: 'Actions',
      shortcut: ['⌘', '⌫'],
      icon: icon(trash),
    },
  ];

  const rulerIcon = icon(ruler);
  const commandIcon = icon(command);
  const pxPer: Record<string, number> = {
    px: 1,
    pt: 96 / 72,
    mm: 96 / 25.4,
    in: 96,
  };

  /** The Omnibox units answer, for lengths only: "12 pt" answers in the other units. */
  function answers(query: string): CanonCommandItem[] {
    const match = /^(-?\d+(?:\.\d+)?)\s*(px|pt|mm|in)$/i.exec(query.trim());
    if (!match) return [];
    const unit = match[2]!.toLowerCase();
    const px = Number(match[1]) * pxPer[unit]!;
    const title = Object.keys(pxPer)
      .filter((other) => other !== unit)
      .map((other) => `${+(px / pxPer[other]!).toFixed(2)} ${other}`)
      .join(' · ');
    return [
      {
        id: 'answer',
        title,
        detail: query.trim(),
        answer: true,
        icon: rulerIcon,
      },
    ];
  }

  const formats = ['ASE', 'GPL', 'JSON'];
  const units = ['px', 'pt', 'mm'];
  const edges: { edge: CanonSheetEdge; title: string; svg: string }[] = [
    { edge: 'bottom', title: 'Bottom', svg: panelBottom },
    { edge: 'top', title: 'Top', svg: panelTop },
    { edge: 'start', title: 'Start', svg: panelLeft },
    { edge: 'end', title: 'End', svg: panelRight },
  ];

  let query = $state('');
  let paletteQuery = $state('');
  let picked = $state('');
  let paletteOpen = $state(false);
  let dialog = $state(false);
  let alert = $state(false);
  let sheet = $state<CanonSheetEdge>();
  let returned = $state('');

  const commandItems = $derived([...answers(query), ...items]);
  const paletteItems = $derived([...answers(paletteQuery), ...items]);

  // consumer owns the shortcut
  const shortcut: Attachment = () => {
    const keydown = (event: KeyboardEvent) => {
      if (event.key.toLowerCase() !== 'k') return;
      if (!(event.metaKey || event.ctrlKey) || event.altKey) return;
      event.preventDefault();
      paletteOpen = true;
    };
    document.addEventListener('keydown', keydown);
    return () => document.removeEventListener('keydown', keydown);
  };

  function run(close: CanonDialogClose, item: CanonCommandItem) {
    picked = item.title;
    close(item.id);
  }
</script>

<CanonRows framed {@attach shortcut}>
  <CanonHeading text="Command" />
  <CanonCommand
    items={commandItems}
    placeholder="Search tools"
    onSelect={(item) => (picked = item.title)}
    onQuery={(text) => (query = text)}
  />
  <CanonRow title="Picked" detail={picked ? picked : '—'} />
  <CanonHeading text="Dialogs" />
  <CanonRow title="Palette" detail="⌘K or Ctrl+K" form="flush">
    <CanonButton
      kind="cell"
      text="Open"
      icon={commandIcon}
      onClick={() => (paletteOpen = true)}
    />
  </CanonRow>
  <CanonGrid>
    <CanonButton text="Dialog" onClick={() => (dialog = true)} />
    <CanonButton text="Alert" onClick={() => (alert = true)} />
  </CanonGrid>
  <CanonRow title="Returned" detail={returned ? returned : '—'} />
  <CanonHeading text="Sheets" />
  <CanonGrid>
    {#each edges as e (e.edge)}
      <CanonButton
        text={e.title}
        icon={icon(e.svg)}
        onClick={() => (sheet = e.edge)}
      />
    {/each}
  </CanonGrid>
</CanonRows>

<CanonDialog
  open={paletteOpen}
  onClose={() => {
    paletteOpen = false;
    paletteQuery = '';
  }}
  aria-label="Command palette"
  style="--canon-dialog-width: 640px"
>
  {#snippet children(close)}
    <CanonCommand
      items={paletteItems}
      placeholder="Search tools"
      onSelect={(item) => run(close, item)}
      onQuery={(text) => (paletteQuery = text)}
    />
  {/snippet}
</CanonDialog>

<CanonDialog
  open={dialog}
  title="Export palette"
  message={exportMessage}
  onClose={(value) => {
    dialog = false;
    returned = value;
  }}
>
  <CanonRow title="Format" form="stacked">
    {#snippet children(titleId)}
      <CanonSegmented items={formats} aria-labelledby={titleId} />
    {/snippet}
  </CanonRow>
  <CanonRow title="Include names">
    {#snippet children(titleId)}
      <CanonSwitch on aria-labelledby={titleId} />
    {/snippet}
  </CanonRow>
  {#snippet footer(close)}
    <CanonButton text="Cancel" onClick={() => close('cancel')} />
    <CanonButton text="Export" selected onClick={() => close('export')} />
  {/snippet}
</CanonDialog>

<CanonDialog
  open={alert}
  alert
  title="Delete palette?"
  message={deleteMessage}
  onClose={(value) => {
    alert = false;
    returned = value;
  }}
>
  {#snippet footer(close)}
    <CanonButton text="Cancel" onClick={() => close('cancel')} />
    <CanonButton text="Delete" selected onClick={() => close('delete')} />
  {/snippet}
</CanonDialog>

{#each edges as e (e.edge)}
  <CanonSheet
    open={sheet === e.edge}
    edge={e.edge}
    title={e.title}
    onClose={() => (sheet = undefined)}
  >
    <CanonRow title="Snap to grid">
      {#snippet children(titleId)}
        <CanonSwitch on aria-labelledby={titleId} />
      {/snippet}
    </CanonRow>
    <CanonRow title="Show rulers">
      {#snippet children(titleId)}
        <CanonSwitch aria-labelledby={titleId} />
      {/snippet}
    </CanonRow>
    <CanonRow title="Units" form="stacked">
      {#snippet children(titleId)}
        <CanonSegmented items={units} aria-labelledby={titleId} />
      {/snippet}
    </CanonRow>
    {#snippet footer(close)}
      <CanonButton text="Done" onClick={() => close('')} />
    {/snippet}
  </CanonSheet>
{/each}
