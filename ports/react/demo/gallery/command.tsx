import { useEffect, useState, type CSSProperties } from 'react';
import CanonButton from '../../src/components/canon-button.tsx';
import CanonCommand, {
  type CanonCommandItem,
} from '../../src/components/canon-command.tsx';
import CanonDialog from '../../src/components/canon-dialog.tsx';
import CanonGrid from '../../src/components/canon-grid.tsx';
import CanonHeading from '../../src/components/canon-heading.tsx';
import CanonIcon from '../../src/components/canon-icon.tsx';
import CanonRow from '../../src/components/canon-row.tsx';
import CanonRows from '../../src/components/canon-rows.tsx';
import CanonSegmented from '../../src/components/canon-segmented.tsx';
import CanonSheet, {
  type CanonSheetEdge,
} from '../../src/components/canon-sheet.tsx';
import CanonSwitch from '../../src/components/canon-switch.tsx';
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
    icon: <CanonIcon svg={contrast} />,
  },
  {
    id: 'shades',
    title: 'Tailwind shades',
    group: 'Colour',
    keywords: ['palette', 'scale'],
    icon: <CanonIcon svg={palette} />,
  },
  {
    id: 'harmony',
    title: 'Harmony genny',
    group: 'Colour',
    keywords: ['complementary', 'triad'],
    icon: <CanonIcon svg={blend} />,
  },
  {
    id: 'case',
    title: 'Case converter',
    group: 'Text',
    keywords: ['upper', 'lower', 'title'],
    icon: <CanonIcon svg={caseSensitive} />,
  },
  {
    id: 'count',
    title: 'Word counter',
    group: 'Text',
    detail: 'Text › Analysis',
    icon: <CanonIcon svg={text} />,
  },
  {
    id: 'hash',
    title: 'Hash generator',
    group: 'Text',
    keywords: ['sha', 'md5'],
    icon: <CanonIcon svg={hashSvg} />,
  },
  {
    id: 'copy',
    title: 'Copy',
    group: 'Actions',
    shortcut: ['⌘', 'C'],
    icon: <CanonIcon svg={copy} />,
  },
  {
    id: 'paste',
    title: 'Paste',
    group: 'Actions',
    shortcut: ['⌘', 'V'],
    disabled: true,
    icon: <CanonIcon svg={clipboardPaste} />,
  },
  {
    id: 'delete',
    title: 'Delete palette',
    group: 'Actions',
    shortcut: ['⌘', '⌫'],
    icon: <CanonIcon svg={trash} />,
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
      icon: <CanonIcon svg={ruler} />,
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
const paletteStyle = { '--canon-dialog-width': '640px' } as CSSProperties;

export default function Command() {
  const [query, setQuery] = useState('');
  const [paletteQuery, setPaletteQuery] = useState('');
  const [picked, setPicked] = useState('');
  const [paletteOpen, setPaletteOpen] = useState(false);
  const [dialog, setDialog] = useState(false);
  const [alert, setAlert] = useState(false);
  const [sheet, setSheet] = useState<CanonSheetEdge>();
  const [returned, setReturned] = useState('');

  // consumer owns the shortcut
  useEffect(() => {
    const keydown = (event: KeyboardEvent) => {
      if (event.key.toLowerCase() !== 'k') return;
      if (!(event.metaKey || event.ctrlKey) || event.altKey) return;
      event.preventDefault();
      setPaletteOpen(true);
    };
    document.addEventListener('keydown', keydown);
    return () => document.removeEventListener('keydown', keydown);
  }, []);

  return (
    <>
      <CanonRows framed>
        <CanonHeading text="Command" />
        <CanonCommand
          items={[...answers(query), ...items]}
          placeholder="Search tools"
          onSelect={(item) => setPicked(item.title)}
          onQuery={setQuery}
        />
        <CanonRow title="Picked" detail={picked || '—'} />
        <CanonHeading text="Dialogs" />
        <CanonRow title="Palette" detail="⌘K or Ctrl+K" form="flush">
          <CanonButton
            kind="cell"
            text="Open"
            icon={<CanonIcon svg={command} />}
            onClick={() => setPaletteOpen(true)}
          />
        </CanonRow>
        <CanonGrid>
          <CanonButton text="Dialog" onClick={() => setDialog(true)} />
          <CanonButton text="Alert" onClick={() => setAlert(true)} />
        </CanonGrid>
        <CanonRow title="Returned" detail={returned || '—'} />
        <CanonHeading text="Sheets" />
        <CanonGrid>
          {edges.map((e) => (
            <CanonButton
              key={e.edge}
              text={e.title}
              icon={<CanonIcon svg={e.svg} />}
              onClick={() => setSheet(e.edge)}
            />
          ))}
        </CanonGrid>
      </CanonRows>

      <CanonDialog
        open={paletteOpen}
        onClose={() => {
          setPaletteOpen(false);
          setPaletteQuery('');
        }}
        aria-label="Command palette"
        style={paletteStyle}
      >
        {(close) => (
          <CanonCommand
            items={[...answers(paletteQuery), ...items]}
            placeholder="Search tools"
            onSelect={(item) => {
              setPicked(item.title);
              close(item.id);
            }}
            onQuery={setPaletteQuery}
          />
        )}
      </CanonDialog>

      <CanonDialog
        open={dialog}
        title="Export palette"
        message={exportMessage}
        onClose={(value) => {
          setDialog(false);
          setReturned(value);
        }}
        footer={(close) => (
          <>
            <CanonButton text="Cancel" onClick={() => close('cancel')} />
            <CanonButton
              text="Export"
              selected
              onClick={() => close('export')}
            />
          </>
        )}
      >
        <CanonRow title="Format" form="stacked">
          {(titleId) => (
            <CanonSegmented items={formats} aria-labelledby={titleId} />
          )}
        </CanonRow>
        <CanonRow title="Include names">
          {(titleId) => <CanonSwitch on aria-labelledby={titleId} />}
        </CanonRow>
      </CanonDialog>

      <CanonDialog
        open={alert}
        alert
        title="Delete palette?"
        message={deleteMessage}
        onClose={(value) => {
          setAlert(false);
          setReturned(value);
        }}
        footer={(close) => (
          <>
            <CanonButton text="Cancel" onClick={() => close('cancel')} />
            <CanonButton
              text="Delete"
              selected
              onClick={() => close('delete')}
            />
          </>
        )}
      />

      {edges.map((e) => (
        <CanonSheet
          key={e.edge}
          open={sheet === e.edge}
          edge={e.edge}
          title={e.title}
          onClose={() => setSheet(undefined)}
          footer={(close) => (
            <CanonButton text="Done" onClick={() => close('')} />
          )}
        >
          <CanonRow title="Snap to grid">
            {(titleId) => <CanonSwitch on aria-labelledby={titleId} />}
          </CanonRow>
          <CanonRow title="Show rulers">
            {(titleId) => <CanonSwitch aria-labelledby={titleId} />}
          </CanonRow>
          <CanonRow title="Units" form="stacked">
            {(titleId) => (
              <CanonSegmented items={units} aria-labelledby={titleId} />
            )}
          </CanonRow>
        </CanonSheet>
      ))}
    </>
  );
}
