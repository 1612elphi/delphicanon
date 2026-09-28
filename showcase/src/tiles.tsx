import { useMemo, useState, type ComponentType } from 'react';
import { hex, parseHex, type Rgb } from '@canon/lib/colour.ts';
import { solidSpaces, spaceNames } from '@canon/lib/colour-space.ts';
import type { GlyphKind } from '@canon/lib/glyph-rows.ts';
import { frame } from '@canon/lib/loupe.ts';
import { Expression, type Key } from '@canon/lib/math/expression.ts';
import CanonBar from '@port/components/canon-bar.tsx';
import CanonBigNumberField from '@port/components/canon-big-number-field.tsx';
import CanonButton from '@port/components/canon-button.tsx';
import CanonCanvas from '@port/components/canon-canvas.tsx';
import CanonCodeBlock from '@port/components/canon-code-block.tsx';
import CanonColourCard from '@port/components/canon-colour-card.tsx';
import CanonColourControls, {
  useCanonColourSolidState,
} from '@port/components/canon-colour-controls.tsx';
import CanonColourNotationInput from '@port/components/canon-colour-notation-input.tsx';
import CanonColourSolid from '@port/components/canon-colour-solid.tsx';
import CanonColourStrip from '@port/components/canon-colour-strip.tsx';
import CanonColourWell from '@port/components/canon-colour-well.tsx';
import CanonDecimalField from '@port/components/canon-decimal-field.tsx';
import CanonDetentWheel from '@port/components/canon-detent-wheel.tsx';
import CanonDetentWheelRow from '@port/components/canon-detent-wheel-row.tsx';
import CanonDropZone from '@port/components/canon-drop-zone.tsx';
import CanonDualList, {
  type CanonDualItem,
} from '@port/components/canon-dual-list.tsx';
import CanonEmptyRow from '@port/components/canon-empty-row.tsx';
import CanonFigure from '@port/components/canon-figure.tsx';
import CanonFileCell from '@port/components/canon-file-cell.tsx';
import CanonFromTo from '@port/components/canon-from-to.tsx';
import CanonGlyphFlow from '@port/components/canon-glyph-flow.tsx';
import CanonGrid from '@port/components/canon-grid.tsx';
import CanonHeading from '@port/components/canon-heading.tsx';
import CanonIcon from '@port/components/canon-icon.tsx';
import CanonImageCompare from '@port/components/canon-image-compare.tsx';
import CanonLamps from '@port/components/canon-lamps.tsx';
import CanonLoader from '@port/components/canon-loader.tsx';
import CanonLoupe from '@port/components/canon-loupe.tsx';
import CanonMathEditor from '@port/components/canon-math-editor.tsx';
import CanonMathField, {
  CanonMathFieldHandle,
} from '@port/components/canon-math-field.tsx';
import CanonMathInput from '@port/components/canon-math-input.tsx';
import CanonMathKey from '@port/components/canon-math-key.tsx';
import CanonMathKeypad from '@port/components/canon-math-keypad.tsx';
import CanonMathRail from '@port/components/canon-math-rail.tsx';
import CanonMathTabs from '@port/components/canon-math-tabs.tsx';
import CanonMathView from '@port/components/canon-math-view.tsx';
import CanonMenuCell from '@port/components/canon-menu-cell.tsx';
import CanonNumberField from '@port/components/canon-number-field.tsx';
import CanonPage from '@port/components/canon-page.tsx';
import CanonPageStrip, {
  pageStripHeight,
  type CanonPage as CanonPageItem,
} from '@port/components/canon-page-strip.tsx';
import CanonPaletteCard from '@port/components/canon-palette-card.tsx';
import CanonPreviewPanel from '@port/components/canon-preview-panel.tsx';
import CanonReadoutBand from '@port/components/canon-readout-band.tsx';
import CanonRow from '@port/components/canon-row.tsx';
import CanonRows from '@port/components/canon-rows.tsx';
import CanonRule from '@port/components/canon-rule.tsx';
import CanonSegmented from '@port/components/canon-segmented.tsx';
import CanonSlider from '@port/components/canon-slider.tsx';
import CanonSplit from '@port/components/canon-split.tsx';
import CanonStatus from '@port/components/canon-status.tsx';
import CanonStepper from '@port/components/canon-stepper.tsx';
import CanonSwatch from '@port/components/canon-swatch.tsx';
import CanonSwitch from '@port/components/canon-switch.tsx';
import CanonTextArea from '@port/components/canon-text-area.tsx';
import CanonTextCell from '@port/components/canon-text-cell.tsx';
import CanonTextInput from '@port/components/canon-text-input.tsx';
import CanonTextOutput from '@port/components/canon-text-output.tsx';
import CanonTiles from '@port/components/canon-tiles.tsx';
import CanonTimecode from '@port/components/canon-timecode.tsx';
import CanonValueLine from '@port/components/canon-value-line.tsx';
import { MathEditing } from '@port/lib/math-editing.ts';
import { canonToast } from '@port/lib/toast-store.ts';
import GalleryArt from '../../ports/react/demo/gallery-art.tsx';
import bug from 'lucide-static/icons/bug.svg?raw';
import circleDot from 'lucide-static/icons/circle-dot.svg?raw';
import copy from 'lucide-static/icons/copy.svg?raw';
import file from 'lucide-static/icons/file.svg?raw';
import messageSquareCheck from 'lucide-static/icons/message-square-check.svg?raw';
import moveHorizontal from 'lucide-static/icons/move-horizontal.svg?raw';
import play from 'lucide-static/icons/play.svg?raw';
import repeat from 'lucide-static/icons/repeat.svg?raw';
import rotateCw from 'lucide-static/icons/rotate-cw.svg?raw';
import share from 'lucide-static/icons/share.svg?raw';
import square from 'lucide-static/icons/square.svg?raw';
import zoomIn from 'lucide-static/icons/zoom-in.svg?raw';
import zoomOut from 'lucide-static/icons/zoom-out.svg?raw';

// ∑CG: showcase, prompt inside the drop zone tile
//   spec: invites dropping a file onto the area; four to six words, sentence case, no period
//   sample: "Drop an image here"
const dropPrompt = '∑CG';

const icon = (svg: string) => <CanonIcon svg={svg} />;
const hexes = (codes: string[]): Rgb[] => codes.map((code) => parseHex(code)!);
const forest: Rgb = [0.118, 0.4, 0.149];
const harmony = hexes(['1E6626', '2E7D6B', '4F6B1E']);
const shades = hexes([
  'E8F3E6',
  'C4E0BF',
  '93C68B',
  '5FA656',
  '3A8535',
  '1E6626',
  '154A1B',
  '0C3011',
  '051A08',
]);
const rates = ['23.976', '24', '25'];
const modes = ['Region', 'Window', 'Screen', 'Timed'];
const whole = (value: number) => String(Math.round(value));
const smpte = () => '01:02:03:04';
const spaceName = (index: number) => spaceNames[solidSpaces[index]!];

function hsv(h: number, s: number, v: number) {
  const f = (n: number) => {
    const k = (n + h * 6) % 6;
    return Math.round(255 * (v - v * s * Math.max(0, Math.min(k, 4 - k, 1))));
  };
  return `rgb(${f(5)},${f(3)},${f(1)})`;
}

function bands(saturation: number) {
  const rects = Array.from(
    { length: 32 },
    (_, x) =>
      `<rect x="${x * 10}" width="10" height="160" shape-rendering="crispEdges" fill="${hsv(x / 32, saturation, 0.9)}"/>`,
  ).join('');
  return `data:image/svg+xml,${encodeURIComponent(
    `<svg xmlns="http://www.w3.org/2000/svg" width="320" height="160">${rects}</svg>`,
  )}`;
}

const before = bands(0.8);
const after = bands(0);

// the colour's shades around the middle pixel, as the iOS gallery draws them
function loupePixels(colour: Rgb): ImageData {
  const side = 15;
  const pixels = new ImageData(side, side);
  for (let y = 0; y < side; y++) {
    for (let x = 0; x < side; x++) {
      const toward = (x + y) % 2 === 0 ? 1 : 0;
      const by = (Math.abs(x - 7) + Math.abs(y - 7)) / 16;
      const at = (y * side + x) * 4;
      colour.forEach((channel, i) => {
        pixels.data[at + i] = Math.round(
          (channel + (toward - channel) * by) * 255,
        );
      });
      pixels.data[at + 3] = 255;
    }
  }
  return pixels;
}

function placeLoupe(loupe: HTMLDivElement) {
  const box = loupe.parentElement!;
  const observer = new ResizeObserver(() => {
    const { clientWidth: width, clientHeight: height } = box;
    const spot = frame(
      { x: width / 2, y: height / 2 },
      112,
      24,
      { width, height },
      8,
    );
    loupe.style.insetInlineStart = `${spot.x}px`;
    loupe.style.insetBlockStart = `${spot.y}px`;
  });
  observer.observe(box);
  return () => observer.disconnect();
}

const loupe = loupePixels(forest);

function BigNumber() {
  const [big, setBig] = useState('16');
  const step = (direction: -1 | 1) =>
    setBig(String(Math.max(0, (parseInt(big) || 0) + direction)));
  return (
    <CanonBigNumberField
      value={big}
      placeholder="0"
      unit="PX"
      label="Big number"
      onStep={step}
      onInput={setBig}
    />
  );
}

function Canvas() {
  const [lines, setLines] = useState(1);
  return (
    <>
      <CanonCanvas aspect={4}>
        <GalleryArt label="Column canvas" />
      </CanonCanvas>
      <CanonCanvas fitting animated>
        <button
          type="button"
          className="gallery-fit"
          onClick={() => setLines((lines % 4) + 1)}
        >
          {Array.from({ length: lines }, (_, i) => (
            <span key={i}>Line {i + 1}</span>
          ))}
        </button>
      </CanonCanvas>
    </>
  );
}

function ColourControls() {
  const state = useCanonColourSolidState({ space: 'hsl' });
  return <CanonColourControls state={state} />;
}

function ColourNotation() {
  const [colour, setColour] = useState(forest);
  return (
    <CanonRow title="Any notation" form="stacked">
      {(titleId) => (
        <CanonColourNotationInput
          colour={colour}
          onColour={setColour}
          labelledBy={titleId}
        />
      )}
    </CanonRow>
  );
}

function ColourSolid() {
  const state = useCanonColourSolidState({ space: 'hsl' });
  return (
    <CanonCanvas aspect={1} background="var(--canon-muted)">
      <CanonColourSolid
        space={state.space}
        point={state.point}
        animated={state.animated}
        sliceAxis={state.sliceAxis}
        isOrtho={state.isOrtho}
        showsWhole={state.showsWhole}
        onChange={state.pick}
      />
    </CanonCanvas>
  );
}

function ColourWells() {
  const [foreground, setForeground] = useState(forest);
  const [orange, setOrange] = useState<Rgb>([1, 0.584, 0]);
  return (
    <>
      <CanonColourWell
        label="Foreground"
        colour={foreground}
        format="oklch"
        onChange={setForeground}
      />
      <CanonColourWell colour={orange} onChange={setOrange} />
    </>
  );
}

function DecimalField() {
  const [seconds, setSeconds] = useState(1.5);
  return (
    <CanonRow title="Decimal" form="flush">
      {(titleId) => (
        <CanonDecimalField
          value={seconds}
          labelledBy={titleId}
          onChange={setSeconds}
        />
      )}
    </CanonRow>
  );
}

function DetentWheel() {
  const [selected, setSelected] = useState(0);
  return (
    <CanonCanvas height={200}>
      <CanonDetentWheel
        count={solidSpaces.length}
        selected={selected}
        onSelect={setSelected}
        text={spaceName}
        label="Space"
      >
        {(index, focus) => (
          <CanonDetentWheelRow focus={focus}>
            {spaceName(index)}
          </CanonDetentWheelRow>
        )}
      </CanonDetentWheel>
    </CanonCanvas>
  );
}

function DualList() {
  const [hidden, setHidden] = useState<CanonDualItem[]>([
    { id: 'b', name: 'Beta', caption: 'two' },
    { id: 'd', name: 'Delta', caption: 'four' },
  ]);
  const [shown, setShown] = useState<CanonDualItem[]>([
    { id: 'a', name: 'Alpha', caption: 'one' },
    { id: 'c', name: 'Gamma', caption: 'three' },
  ]);

  const moveRight = (id: string) => {
    const item = hidden.find((i) => i.id === id);
    if (!item) return;
    setHidden(hidden.filter((i) => i !== item));
    setShown([...shown, item]);
  };

  const moveLeft = (id: string) => {
    const item = shown.find((i) => i.id === id);
    if (!item) return;
    setShown(shown.filter((i) => i !== item));
    setHidden([...hidden, item]);
  };

  const reorder = (id: string, delta: -1 | 1) => {
    const index = shown.findIndex((i) => i.id === id);
    const other = index + delta;
    if (index < 0 || other < 0 || other >= shown.length) return;
    const next = [...shown];
    [next[index], next[other]] = [next[other]!, next[index]!];
    setShown(next);
  };

  return (
    <CanonDualList
      left={hidden}
      right={shown}
      leftTitle="Hidden"
      rightTitle="Shown"
      listHeight={140}
      onMoveRight={moveRight}
      onMoveLeft={moveLeft}
      onReorder={reorder}
    />
  );
}

interface NumberRowProps {
  value: number;
  onChange: (value: number) => void;
}

function NumberRow({ value, onChange }: NumberRowProps) {
  return (
    <CanonRow title="Number" form="flush">
      {(titleId) => (
        <CanonNumberField
          value={value}
          max={5000}
          step={50}
          unit="items"
          labelledBy={titleId}
          onChange={onChange}
        />
      )}
    </CanonRow>
  );
}

function NumberField() {
  const [number, setNumber] = useState(200);
  return <NumberRow value={number} onChange={setNumber} />;
}

function Figure() {
  const [number, setNumber] = useState(200);
  return (
    <>
      <NumberRow value={number} onChange={setNumber} />
      <CanonRow title="Figure" detail="Follows Number">
        <CanonFigure text={String(number)} unit="px" size={28} />
      </CanonRow>
    </>
  );
}

const glyphMetrics = { height: 36, rowGap: 8, gap: 4 };
const measureGlyph = () => 28;
const glyphKind = (c: string): GlyphKind =>
  c === '\n' ? 'newline' : /\s/.test(c) ? 'space' : 'glyph';
const isSpace = (c: string) => /\s/.test(c);

function GlyphFlow() {
  const [text, setText] = useState('Glyph flow');
  const glyphs = useMemo(() => [...text], [text]);
  return (
    <>
      <CanonCanvas height={120}>
        <CanonGlyphFlow
          glyphs={glyphs}
          metrics={glyphMetrics}
          measure={measureGlyph}
          kind={glyphKind}
          label={text}
        >
          {(glyph) =>
            !isSpace(glyph) && <span className="gallery-glyph">{glyph}</span>
          }
        </CanonGlyphFlow>
      </CanonCanvas>
      <CanonTextInput value={text} onChange={setText} />
    </>
  );
}

function MathEditor() {
  const [editing] = useState(
    () => new MathEditing(new Expression('(x+1)^2/2')),
  );
  return (
    <div className="showcase-editor">
      <CanonMathEditor editing={editing} />
    </div>
  );
}

const inserts: Key[] = [
  { kind: 'fraction' },
  { kind: 'power' },
  { kind: 'root' },
  { kind: 'symbol', symbol: '×' },
];

function MathField() {
  const [handle] = useState(() => new CanonMathFieldHandle());
  return (
    <>
      <CanonMathField text="(x+1)^2/2" placeholder="x^2 - 4" handle={handle} />
      <CanonGrid columns={4}>
        {inserts.map((key, i) => (
          <CanonMathKey
            key={i}
            mathKey={key}
            onClick={() => handle.edit([key])}
          />
        ))}
      </CanonGrid>
    </>
  );
}

function MathInput() {
  const [open, setOpen] = useState(false);
  const [text, setText] = useState('sqrt(x^2+1)/(2*x)');
  const close = (next: string) => {
    setText(next);
    setOpen(false);
  };
  return (
    <>
      <div className="showcase-stage">
        <CanonMathView text={text} size={22} />
      </div>
      <CanonButton text="Open" onClick={() => setOpen(true)} />
      {open && <CanonMathInput text={text} onClose={close} />}
    </>
  );
}

function MathTabs() {
  const [page, setPage] = useState(0);
  return <CanonMathTabs progress={page} onSelect={setPage} />;
}

const morphs = ['(x+1)^2', 'x^2+2*x+1', '(x+1)*(x+1)'];

function MathView() {
  const [morph, setMorph] = useState(0);
  return (
    <>
      <div className="showcase-stage">
        <CanonMathView text="sqrt(x^2+1)/(2*x)" size={22} />
        <CanonMathView text="sum(k^2,k,1,n)" size={22} />
        <CanonMathView text="b*c^(-1)+(1/2)*x^(-1/2)" presents />
      </div>
      <CanonCanvas height={120}>
        <CanonMathView
          text={morphs[morph % morphs.length]}
          size={30}
          morphs
          style={{ blockSize: '100%' }}
        />
      </CanonCanvas>
      <CanonButton text="Morph" onClick={() => setMorph(morph + 1)} />
    </>
  );
}

const startPages: CanonPageItem[] = [
  { size: { width: 595, height: 842 }, name: 'Plain' },
  { size: { width: 842, height: 595 }, name: 'Lit' },
  { size: { width: 595, height: 842 }, name: 'Depth 2', depth: 2 },
  {
    size: { width: 595, height: 842 },
    name: 'Picture',
    picture: before,
    area: { x: 40, y: 60, width: 515, height: 722 },
    placement: { x: 40, y: 262, width: 515, height: 320 },
    turn: 90,
  },
];

function PageStrip() {
  const [pages, setPages] = useState(startPages);
  const [selected, setSelected] = useState(1);

  const move = (from: number, to: number) => {
    const next = [...pages];
    next.splice(to, 0, ...next.splice(from, 1));
    if (selected === from) setSelected(to);
    setPages(next);
  };

  const menu = (index: number) => [
    {
      title: 'Duplicate',
      action: () =>
        setPages((current) => {
          const next = [...current];
          next.splice(index + 1, 0, current[index]!);
          return next;
        }),
    },
    {
      title: 'Delete',
      action: () =>
        setPages((current) => current.filter((_, i) => i !== index)),
      destructive: true,
    },
  ];

  return (
    <CanonCanvas height={pageStripHeight} background="var(--canon-muted)">
      <CanonPageStrip
        pages={pages}
        selected={selected}
        onSelect={setSelected}
        reorders
        onMove={move}
        menu={menu}
      />
    </CanonCanvas>
  );
}

function Stepper() {
  const [count, setCount] = useState(3);
  return (
    <CanonStepper onStep={(direction) => setCount(count + direction)}>
      <span className="canon-stepper-value">{count}</span>
    </CanonStepper>
  );
}

function TextInput() {
  const [text, setText] = useState('Glyph flow');
  return (
    <>
      <CanonTextInput value={text} onChange={setText} />
      <CanonStatus text={text} tone="muted" row />
    </>
  );
}

const loopPlayStop = (
  <CanonGrid>
    <CanonButton text="Loop" icon={icon(repeat)} />
    <CanonButton text="Play" icon={icon(play)} kind="primary" />
    <CanonButton text="Stop" icon={icon(square)} />
  </CanonGrid>
);

export interface Tile {
  /** The registry item name, `canon-<name>`. */
  name: string;
  /** Spans two columns where the grid has them. */
  wide?: boolean;
  Live: ComponentType;
}

export const tiles: Tile[] = [
  {
    name: 'canon-bar',
    Live: () => (
      <>
        <CanonRow title="Plain">
          <CanonBar className="gallery-bar" share={0.65} />
        </CanonRow>
        <CanonRow title="Low">
          <CanonBar className="gallery-bar" share={0.3} />
        </CanonRow>
      </>
    ),
  },
  { name: 'canon-big-number-field', Live: BigNumber },
  {
    name: 'canon-button',
    Live: () => (
      <>
        <CanonButton text="Generate" icon={icon(rotateCw)} kind="primary" />
        <CanonGrid>
          <CanonButton text="Copy" icon={icon(copy)} />
          <CanonButton text="Export" icon={icon(share)} kind="primary" />
        </CanonGrid>
        <CanonButton text="Copy" icon={icon(copy)} flashesCopied />
      </>
    ),
  },
  { name: 'canon-canvas', Live: Canvas },
  {
    name: 'canon-code-block',
    Live: () => (
      <CanonCodeBlock
        code={`.button {\n    border-radius: 0;\n    color: oklch(0.45 0.12 145);\n}`}
        language="css"
      />
    ),
  },
  {
    name: 'canon-colour-card',
    Live: () => (
      <>
        <CanonColourCard colour={forest} />
        <CanonColourCard colour={forest} layout="row" />
      </>
    ),
  },
  { name: 'canon-colour-controls', wide: true, Live: ColourControls },
  { name: 'canon-colour-notation-input', Live: ColourNotation },
  { name: 'canon-colour-solid', Live: ColourSolid },
  {
    name: 'canon-colour-strip',
    Live: () => <CanonColourStrip colour={forest} palette={harmony} />,
  },
  { name: 'canon-colour-well', Live: ColourWells },
  { name: 'canon-decimal-field', Live: DecimalField },
  { name: 'canon-detent-wheel', Live: DetentWheel },
  {
    name: 'canon-detent-wheel-row',
    Live: () => (
      <div className="showcase-wheel-rows">
        <CanonDetentWheelRow focus={0}>HSV</CanonDetentWheelRow>
        <CanonDetentWheelRow focus={1}>HSL</CanonDetentWheelRow>
        <CanonDetentWheelRow focus={0.3}>OKLCH</CanonDetentWheelRow>
      </div>
    ),
  },
  {
    name: 'canon-drop-zone',
    Live: () => (
      <CanonDropZone
        prompt={dropPrompt}
        icon={icon(file)}
        accept=""
        multiple
        paste={false}
      />
    ),
  },
  { name: 'canon-dual-list', Live: DualList },
  {
    name: 'canon-empty-row',
    Live: () => <CanonEmptyRow text="Nothing here" />,
  },
  { name: 'canon-figure', Live: Figure },
  {
    name: 'canon-file-cell',
    Live: () => (
      <>
        <CanonRow title="File" form="flush">
          {(titleId) => <CanonFileCell labelledBy={titleId} />}
        </CanonRow>
        <CanonRow title="Image" form="flush">
          {(titleId) => <CanonFileCell accept="image/*" labelledBy={titleId} />}
        </CanonRow>
      </>
    ),
  },
  {
    name: 'canon-from-to',
    Live: () => <CanonFromTo items={rates} from={0} to={2} />,
  },
  { name: 'canon-glyph-flow', Live: GlyphFlow },
  {
    name: 'canon-grid',
    Live: () => (
      <>
        <CanonGrid>
          <CanonButton text="Cancel" />
          <CanonButton text="Apply" kind="primary" />
        </CanonGrid>
        <CanonRow title="Icon actions" detail="3.60 – 6.00" form="flush">
          <CanonGrid>
            <CanonButton kind="cell" icon={icon(zoomOut)} label="Zoom out" />
            <CanonButton kind="cell" icon={icon(zoomIn)} label="Zoom in" />
            <CanonButton
              kind="cell"
              icon={icon(moveHorizontal)}
              label="Fit width"
            />
          </CanonGrid>
        </CanonRow>
      </>
    ),
  },
  { name: 'canon-heading', Live: () => <CanonHeading text="Rows" /> },
  {
    name: 'canon-icon',
    Live: () => (
      <div className="showcase-stage showcase-icons">
        {[bug, rotateCw, copy, share, zoomIn, circleDot].map((svg) => (
          <CanonIcon key={svg} svg={svg} />
        ))}
      </div>
    ),
  },
  {
    name: 'canon-image-compare',
    Live: () => (
      <CanonCanvas aspect={2} background="var(--canon-muted)">
        <CanonImageCompare before={before} after={after} afterTitle="Grey" />
      </CanonCanvas>
    ),
  },
  {
    name: 'canon-lamps',
    Live: () => (
      <div className="showcase-stage">
        <CanonLamps lit={['play', 'loop']} />
        <CanonLamps lamps={['record', 'pause']} lit={['record']} />
      </div>
    ),
  },
  {
    name: 'canon-loader',
    Live: () => (
      <div className="showcase-stage gallery-loaders">
        <CanonLoader />
        <CanonLoader mode="comet" reverse />
        <CanonLoader mode="dot" />
        <CanonLoader mode="twin" />
        <CanonLoader mode="thinking" />
        <CanonLoader cell={4} gap={1} />
      </div>
    ),
  },
  {
    name: 'canon-loupe',
    Live: () => (
      <CanonCanvas height={200} background="var(--canon-muted)">
        <CanonLoupe
          className="gallery-loupe"
          pixels={loupe}
          colour={forest}
          ref={placeLoupe}
        />
      </CanonCanvas>
    ),
  },
  { name: 'canon-math-editor', Live: MathEditor },
  { name: 'canon-math-field', Live: MathField },
  { name: 'canon-math-input', Live: MathInput },
  {
    name: 'canon-math-key',
    Live: () => (
      <CanonGrid columns={4}>
        {inserts.map((key, i) => (
          <CanonMathKey key={i} mathKey={key} />
        ))}
      </CanonGrid>
    ),
  },
  {
    name: 'canon-math-keypad',
    wide: true,
    Live: () => <CanonMathKeypad variable="t" />,
  },
  { name: 'canon-math-rail', Live: () => <CanonMathRail /> },
  { name: 'canon-math-tabs', Live: MathTabs },
  { name: 'canon-math-view', Live: MathView },
  {
    name: 'canon-menu-cell',
    Live: () => (
      <CanonRow title="Menu" form="flush">
        {(titleId) => (
          <CanonMenuCell items={rates} selected={0} labelledBy={titleId} />
        )}
      </CanonRow>
    ),
  },
  { name: 'canon-number-field', Live: NumberField },
  {
    name: 'canon-page',
    Live: () => (
      <div className="showcase-box">
        <CanonPage>
          <CanonCanvas height={64}>
            <GalleryArt label="Page" />
          </CanonCanvas>
          <CanonRows framed>
            <CanonRow title="Plain" />
            <CanonRow title="Scrolls" />
            <CanonRow title="Centred" />
          </CanonRows>
        </CanonPage>
      </div>
    ),
  },
  { name: 'canon-page-strip', wide: true, Live: PageStrip },
  {
    name: 'canon-palette-card',
    Live: () => (
      <>
        <CanonPaletteCard
          title="Harmony"
          colours={harmony}
          actions={
            <CanonButton
              text="Copy"
              icon={icon(copy)}
              kind="cell"
              onClick={() => void canonToast.copy(harmony.map(hex).join('\n'))}
            />
          }
        />
        <CanonPaletteCard title="Shades" colours={shades} height={120} />
      </>
    ),
  },
  {
    name: 'canon-preview-panel',
    Live: () => (
      <CanonPreviewPanel caption="Preview" detail="1600 x 900">
        <div className="gallery-swatch" />
      </CanonPreviewPanel>
    ),
  },
  {
    name: 'canon-readout-band',
    Live: () => (
      <CanonCanvas height={120}>
        <CanonReadoutBand
          transport={{ playhead: 83.4, playing: true, looping: true }}
        >
          <GalleryArt label="Readout over" />
        </CanonReadoutBand>
      </CanonCanvas>
    ),
  },
  {
    name: 'canon-row',
    Live: () => (
      <>
        <CanonRow title="Plain">
          <CanonBar className="gallery-bar" share={0.65} />
        </CanonRow>
        <CanonRow title="Icon" icon={icon(bug)}>
          <CanonBar className="gallery-bar" share={0.3} />
        </CanonRow>
        <CanonRow title="Mode" form="stacked">
          <CanonSegmented items={modes} />
        </CanonRow>
      </>
    ),
  },
  {
    name: 'canon-rows',
    Live: () => (
      <CanonRows>
        <CanonRow title="One" />
        <CanonRow title="Two" />
        <CanonRow title="Three" />
      </CanonRows>
    ),
  },
  {
    name: 'canon-rule',
    Live: () => (
      <div className="showcase-stage showcase-rules">
        <span>Left</span>
        <CanonRule vertical />
        <span>Right</span>
        <CanonRule className="showcase-rule-across" />
      </div>
    ),
  },
  {
    name: 'canon-segmented',
    Live: () => (
      <>
        <CanonRow title="Mode" form="stacked">
          <CanonSegmented items={modes} />
        </CanonRow>
        <CanonSegmented
          items={['Tiny', 'Base', 'Small', 'Large']}
          selected={1}
          disabledIndices={[2, 3]}
        />
      </>
    ),
  },
  {
    name: 'canon-slider',
    Live: () => (
      <>
        <CanonRow title="Slider" form="flush">
          {(titleId) => <CanonSlider value={0.65} labelledBy={titleId} />}
        </CanonRow>
        <CanonRow title="Stepped slider" form="flush">
          {(titleId) => (
            <CanonSlider
              value={80}
              min={1}
              max={100}
              step={1}
              readout={whole}
              labelledBy={titleId}
            />
          )}
        </CanonRow>
      </>
    ),
  },
  {
    name: 'canon-split',
    wide: true,
    Live: () => (
      <div className="showcase-box showcase-box--split">
        <CanonSplit
          banner={
            <CanonCanvas height={64}>
              <GalleryArt label="All columns" />
            </CanonCanvas>
          }
          sidebar={
            <CanonRows framed>
              <CanonHeading text="Sidebar" />
              <CanonRow title="Plain" />
            </CanonRows>
          }
          main={
            <CanonRows framed>
              <CanonHeading text="Main" />
              <CanonRow title="Plain" />
              <CanonRow title="Second" />
            </CanonRows>
          }
          footer={loopPlayStop}
        />
      </div>
    ),
  },
  {
    name: 'canon-status',
    Live: () => (
      <CanonRow title="Status">
        <div className="gallery-inline">
          <CanonStatus text="Granted" tone="ok" />
          <CanonStatus text="Not granted" tone="warn" />
          <CanonStatus text="Stopped" tone="muted" />
        </div>
      </CanonRow>
    ),
  },
  { name: 'canon-stepper', Live: Stepper },
  {
    name: 'canon-swatch',
    Live: () => (
      <div className="showcase-swatches">
        {harmony.map((colour, i) => (
          <CanonSwatch key={i} colour={colour} />
        ))}
      </div>
    ),
  },
  {
    name: 'canon-switch',
    Live: () => (
      <>
        <CanonRow title="Switch">
          {(titleId) => <CanonSwitch on aria-labelledby={titleId} />}
        </CanonRow>
        <CanonGrid>
          {['Images', 'Files'].map((title, index) => (
            <CanonRow key={title} title={title} sizingTitle="Images">
              {(id) => <CanonSwitch on={index === 0} aria-labelledby={id} />}
            </CanonRow>
          ))}
        </CanonGrid>
      </>
    ),
  },
  {
    name: 'canon-text-area',
    Live: () => (
      <CanonTextArea
        placeholder="Text area"
        height={120}
        aria-label="Text area"
      />
    ),
  },
  {
    name: 'canon-text-cell',
    Live: () => (
      <CanonRow title="Text" form="flush">
        {(titleId) => (
          <CanonTextCell placeholder="Trigger" aria-labelledby={titleId} />
        )}
      </CanonRow>
    ),
  },
  { name: 'canon-text-input', Live: TextInput },
  {
    name: 'canon-text-output',
    Live: () => (
      <CanonTextOutput
        text="GLYPH FLOW"
        heading="Text output"
        fileName="showcase.txt"
      />
    ),
  },
  {
    name: 'canon-tiles',
    Live: () => (
      <CanonTiles
        items={[
          { label: 'Codec', value: 'AAC' },
          { label: 'Sample rate', value: '44100 Hz' },
          { label: 'Peak', value: '-4.3 dBFS', level: 0.93 },
          { label: 'RMS', value: '-13.6 dBFS', level: 0.77 },
        ]}
      />
    ),
  },
  {
    name: 'canon-timecode',
    Live: () => (
      <div className="showcase-stage">
        <CanonTimecode seconds={83.4} />
        <CanonTimecode seconds={1} format={smpte} size={28} />
      </div>
    ),
  },
  {
    name: 'canon-toast',
    Live: () => (
      <CanonButton
        text="Toast"
        icon={icon(messageSquareCheck)}
        onClick={() => canonToast.show('#3B82F6')}
      />
    ),
  },
  {
    name: 'canon-value-line',
    Live: () => (
      <>
        <CanonValueLine
          label="Decimal RGB"
          value="rgb(0.1180, 0.4000, 0.1490)"
          labelWidth={92}
        />
        <CanonValueLine label="Above" value="#1E6626" layout="above" />
        <CanonValueLine label="01" value="#1E6626" layout="numbered" lit />
      </>
    ),
  },
];
