<script lang="ts">
export const pane = 'main';
export const order = 8;
</script>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import CanonButton from '../../../src/components/canon-button.vue';
import CanonCommand, {
  type CanonCommandItem,
} from '../../../src/components/canon-command.vue';
import CanonDialog, {
  type CanonDialogClose,
} from '../../../src/components/canon-dialog.vue';
import CanonGrid from '../../../src/components/canon-grid.vue';
import CanonHeading from '../../../src/components/canon-heading.vue';
import CanonRow from '../../../src/components/canon-row.vue';
import CanonRows from '../../../src/components/canon-rows.vue';
import CanonSegmented from '../../../src/components/canon-segmented.vue';
import CanonSheet, {
  type CanonSheetEdge,
} from '../../../src/components/canon-sheet.vue';
import CanonSwitch from '../../../src/components/canon-switch.vue';
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
      icon: icon(ruler),
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

const query = ref('');
const paletteQuery = ref('');
const picked = ref('');
const paletteOpen = ref(false);
const dialogOpen = ref(false);
const alertOpen = ref(false);
const sheet = ref<CanonSheetEdge>();
const returned = ref('');

const allItems = computed(() => [...answers(query.value), ...items]);
const paletteItems = computed(() => [...answers(paletteQuery.value), ...items]);

// consumer owns the shortcut
function shortcut(event: KeyboardEvent) {
  if (event.key.toLowerCase() !== 'k') return;
  if (!(event.metaKey || event.ctrlKey) || event.altKey) return;
  event.preventDefault();
  paletteOpen.value = true;
}
onMounted(() => document.addEventListener('keydown', shortcut));
onBeforeUnmount(() => document.removeEventListener('keydown', shortcut));

const setQuery = (text: string) => (query.value = text);
const setPaletteQuery = (text: string) => (paletteQuery.value = text);
const select = (item: CanonCommandItem) => (picked.value = item.title);
function run(close: CanonDialogClose, item: CanonCommandItem) {
  picked.value = item.title;
  close(item.id);
}

function closePalette() {
  paletteOpen.value = false;
  paletteQuery.value = '';
}
function closeDialog(value: string) {
  dialogOpen.value = false;
  returned.value = value;
}
function closeAlert(value: string) {
  alertOpen.value = false;
  returned.value = value;
}
const closeSheet = () => (sheet.value = undefined);
</script>

<template>
  <CanonRows :framed="true">
    <CanonHeading text="Command" />
    <CanonCommand
      :items="allItems"
      placeholder="Search tools"
      :on-select="select"
      :on-query="setQuery"
    />
    <CanonRow title="Picked" :detail="picked || '—'" />
    <CanonHeading text="Dialogs" />
    <CanonRow title="Palette" detail="⌘K or Ctrl+K" form="flush">
      <CanonButton
        kind="cell"
        text="Open"
        :icon="icon(command)"
        :on-click="() => (paletteOpen = true)"
      />
    </CanonRow>
    <CanonGrid>
      <CanonButton text="Dialog" :on-click="() => (dialogOpen = true)" />
      <CanonButton text="Alert" :on-click="() => (alertOpen = true)" />
    </CanonGrid>
    <CanonRow title="Returned" :detail="returned || '—'" />
    <CanonHeading text="Sheets" />
    <CanonGrid>
      <CanonButton
        v-for="e in edges"
        :key="e.edge"
        :text="e.title"
        :icon="icon(e.svg)"
        :on-click="() => (sheet = e.edge)"
      />
    </CanonGrid>
  </CanonRows>

  <CanonDialog
    :open="paletteOpen"
    :on-close="closePalette"
    aria-label="Command palette"
    style="--canon-dialog-width: 640px"
  >
    <template #default="{ close }">
      <CanonCommand
        :items="paletteItems"
        placeholder="Search tools"
        :on-select="(item: CanonCommandItem) => run(close, item)"
        :on-query="setPaletteQuery"
      />
    </template>
  </CanonDialog>

  <CanonDialog
    :open="dialogOpen"
    title="Export palette"
    :message="exportMessage"
    :on-close="closeDialog"
  >
    <template #default>
      <CanonRow v-slot="{ titleId }" title="Format" form="stacked">
        <CanonSegmented :items="formats" :aria-labelledby="titleId" />
      </CanonRow>
      <CanonRow v-slot="{ titleId }" title="Include names">
        <CanonSwitch :on="true" :aria-labelledby="titleId" />
      </CanonRow>
    </template>
    <template #footer="{ close }">
      <CanonButton text="Cancel" :on-click="() => close('cancel')" />
      <CanonButton
        text="Export"
        :selected="true"
        :on-click="() => close('export')"
      />
    </template>
  </CanonDialog>

  <CanonDialog
    :open="alertOpen"
    :alert="true"
    title="Delete palette?"
    :message="deleteMessage"
    :on-close="closeAlert"
  >
    <template #footer="{ close }">
      <CanonButton text="Cancel" :on-click="() => close('cancel')" />
      <CanonButton
        text="Delete"
        :selected="true"
        :on-click="() => close('delete')"
      />
    </template>
  </CanonDialog>

  <CanonSheet
    v-for="e in edges"
    :key="e.edge"
    :open="sheet === e.edge"
    :edge="e.edge"
    :title="e.title"
    :on-close="closeSheet"
  >
    <template #default>
      <CanonRow v-slot="{ titleId }" title="Snap to grid">
        <CanonSwitch :on="true" :aria-labelledby="titleId" />
      </CanonRow>
      <CanonRow v-slot="{ titleId }" title="Show rulers">
        <CanonSwitch :aria-labelledby="titleId" />
      </CanonRow>
      <CanonRow v-slot="{ titleId }" title="Units" form="stacked">
        <CanonSegmented :items="units" :aria-labelledby="titleId" />
      </CanonRow>
    </template>
    <template #footer="{ close }">
      <CanonButton text="Done" :on-click="() => close('')" />
    </template>
  </CanonSheet>
</template>
