import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import CanonButton from '#src/components/canon-button.gts';
import CanonCommand, {
  type CanonCommandItem,
} from '#src/components/canon-command.gts';
import CanonDialog, {
  type CanonDialogClose,
} from '#src/components/canon-dialog.gts';
import CanonGrid from '#src/components/canon-grid.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonSegmented from '#src/components/canon-segmented.gts';
import CanonSheet, {
  type CanonSheetEdge,
} from '#src/components/canon-sheet.gts';
import CanonSwitch from '#src/components/canon-switch.gts';
import Icon from '../icon.gts';
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

export const pane = 'main';
export const order = 8;

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
    icon: <template><Icon @svg={{contrast}} /></template>,
  },
  {
    id: 'shades',
    title: 'Tailwind shades',
    group: 'Colour',
    keywords: ['palette', 'scale'],
    icon: <template><Icon @svg={{palette}} /></template>,
  },
  {
    id: 'harmony',
    title: 'Harmony genny',
    group: 'Colour',
    keywords: ['complementary', 'triad'],
    icon: <template><Icon @svg={{blend}} /></template>,
  },
  {
    id: 'case',
    title: 'Case converter',
    group: 'Text',
    keywords: ['upper', 'lower', 'title'],
    icon: <template><Icon @svg={{caseSensitive}} /></template>,
  },
  {
    id: 'count',
    title: 'Word counter',
    group: 'Text',
    detail: 'Text › Analysis',
    icon: <template><Icon @svg={{text}} /></template>,
  },
  {
    id: 'hash',
    title: 'Hash generator',
    group: 'Text',
    keywords: ['sha', 'md5'],
    icon: <template><Icon @svg={{hashSvg}} /></template>,
  },
  {
    id: 'copy',
    title: 'Copy',
    group: 'Actions',
    shortcut: ['⌘', 'C'],
    icon: <template><Icon @svg={{copy}} /></template>,
  },
  {
    id: 'paste',
    title: 'Paste',
    group: 'Actions',
    shortcut: ['⌘', 'V'],
    disabled: true,
    icon: <template><Icon @svg={{clipboardPaste}} /></template>,
  },
  {
    id: 'delete',
    title: 'Delete palette',
    group: 'Actions',
    shortcut: ['⌘', '⌫'],
    icon: <template><Icon @svg={{trash}} /></template>,
  },
];

const rulerIcon = <template><Icon @svg={{ruler}} /></template>;
const commandIcon = <template><Icon @svg={{command}} /></template>;
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
const paletteStyle = htmlSafe('--canon-dialog-width: 640px');

export default class CommandGroup extends Component {
  @tracked query = '';
  @tracked paletteQuery = '';
  @tracked picked = '';
  @tracked palette = false;
  @tracked dialog = false;
  @tracked alert = false;
  @tracked sheet?: CanonSheetEdge;
  @tracked returned = '';

  get items() {
    return [...answers(this.query), ...items];
  }

  get paletteItems() {
    return [...answers(this.paletteQuery), ...items];
  }

  // consumer owns the shortcut
  shortcut = modifier(() => {
    const keydown = (event: KeyboardEvent) => {
      if (event.key.toLowerCase() !== 'k') return;
      if (!(event.metaKey || event.ctrlKey) || event.altKey) return;
      event.preventDefault();
      this.palette = true;
    };
    document.addEventListener('keydown', keydown);
    return () => document.removeEventListener('keydown', keydown);
  });

  setQuery = (query: string) => (this.query = query);
  setPaletteQuery = (query: string) => (this.paletteQuery = query);
  select = (item: CanonCommandItem) => (this.picked = item.title);
  run = (close: CanonDialogClose, item: CanonCommandItem) => {
    this.picked = item.title;
    close(item.id);
  };

  openPalette = () => (this.palette = true);
  openDialog = () => (this.dialog = true);
  openAlert = () => (this.alert = true);
  openSheet = (edge: CanonSheetEdge) => (this.sheet = edge);

  closePalette = () => {
    this.palette = false;
    this.paletteQuery = '';
  };
  closeDialog = (value: string) => {
    this.dialog = false;
    this.returned = value;
  };
  closeAlert = (value: string) => {
    this.alert = false;
    this.returned = value;
  };
  closeSheet = () => (this.sheet = undefined);
  isSheet = (edge: CanonSheetEdge) => this.sheet === edge;

  <template>
    <CanonRows @framed={{true}} {{this.shortcut}}>
      <CanonHeading @text="Command" />
      <CanonCommand
        @items={{this.items}}
        @placeholder="Search tools"
        @onSelect={{this.select}}
        @onQuery={{this.setQuery}}
      />
      <CanonRow @title="Picked" @detail={{if this.picked this.picked "—"}} />
      <CanonHeading @text="Dialogs" />
      <CanonRow @title="Palette" @detail="⌘K or Ctrl+K" @form="flush">
        <CanonButton
          @kind="cell"
          @text="Open"
          @icon={{commandIcon}}
          @onClick={{this.openPalette}}
        />
      </CanonRow>
      <CanonGrid>
        <CanonButton @text="Dialog" @onClick={{this.openDialog}} />
        <CanonButton @text="Alert" @onClick={{this.openAlert}} />
      </CanonGrid>
      <CanonRow
        @title="Returned"
        @detail={{if this.returned this.returned "—"}}
      />
      <CanonHeading @text="Sheets" />
      <CanonGrid>
        {{#each edges as |e|}}
          <CanonButton
            @text={{e.title}}
            @icon={{component Icon svg=e.svg}}
            @onClick={{fn this.openSheet e.edge}}
          />
        {{/each}}
      </CanonGrid>
    </CanonRows>

    <CanonDialog
      @open={{this.palette}}
      @onClose={{this.closePalette}}
      aria-label="Command palette"
      style={{paletteStyle}}
    >
      <:default as |close|>
        <CanonCommand
          @items={{this.paletteItems}}
          @placeholder="Search tools"
          @onSelect={{fn this.run close}}
          @onQuery={{this.setPaletteQuery}}
        />
      </:default>
    </CanonDialog>

    <CanonDialog
      @open={{this.dialog}}
      @title="Export palette"
      @message={{exportMessage}}
      @onClose={{this.closeDialog}}
    >
      <:default>
        <CanonRow @title="Format" @form="stacked" as |titleId|>
          <CanonSegmented @items={{formats}} aria-labelledby={{titleId}} />
        </CanonRow>
        <CanonRow @title="Include names" as |titleId|>
          <CanonSwitch @on={{true}} aria-labelledby={{titleId}} />
        </CanonRow>
      </:default>
      <:footer as |close|>
        <CanonButton @text="Cancel" @onClick={{fn close "cancel"}} />
        <CanonButton
          @text="Export"
          @selected={{true}}
          @onClick={{fn close "export"}}
        />
      </:footer>
    </CanonDialog>

    <CanonDialog
      @open={{this.alert}}
      @alert={{true}}
      @title="Delete palette?"
      @message={{deleteMessage}}
      @onClose={{this.closeAlert}}
    >
      <:footer as |close|>
        <CanonButton @text="Cancel" @onClick={{fn close "cancel"}} />
        <CanonButton
          @text="Delete"
          @selected={{true}}
          @onClick={{fn close "delete"}}
        />
      </:footer>
    </CanonDialog>

    {{#each edges as |e|}}
      <CanonSheet
        @open={{this.isSheet e.edge}}
        @edge={{e.edge}}
        @title={{e.title}}
        @onClose={{this.closeSheet}}
      >
        <:default>
          <CanonRow @title="Snap to grid" as |titleId|>
            <CanonSwitch @on={{true}} aria-labelledby={{titleId}} />
          </CanonRow>
          <CanonRow @title="Show rulers" as |titleId|>
            <CanonSwitch aria-labelledby={{titleId}} />
          </CanonRow>
          <CanonRow @title="Units" @form="stacked" as |titleId|>
            <CanonSegmented @items={{units}} aria-labelledby={{titleId}} />
          </CanonRow>
        </:default>
        <:footer as |close|>
          <CanonButton @text="Done" @onClick={{fn close ""}} />
        </:footer>
      </CanonSheet>
    {{/each}}
  </template>
}
