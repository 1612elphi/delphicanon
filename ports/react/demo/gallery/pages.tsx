import { useState } from 'react';
import CanonCanvas from '../../src/components/canon-canvas.tsx';
import CanonImageCompare from '../../src/components/canon-image-compare.tsx';
import CanonPageStrip, {
  pageStripHeight,
  type CanonPage,
} from '../../src/components/canon-page-strip.tsx';

export const pane = 'main';
export const order = 15;

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

const start: CanonPage[] = [
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

export default function Pages() {
  const [pages, setPages] = useState(start);
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
    <>
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
      <CanonCanvas aspect={2} background="var(--canon-muted)">
        <CanonImageCompare before={before} after={after} afterTitle="Grey" />
      </CanonCanvas>
    </>
  );
}
