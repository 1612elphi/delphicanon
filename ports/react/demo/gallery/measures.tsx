import { useCallback, useState } from 'react';
import CanonCanvas from '../../src/components/canon-canvas.tsx';
import CanonCompressionScale from '../../src/components/canon-compression-scale.tsx';
import CanonDimensionLine from '../../src/components/canon-dimension-line.tsx';
import CanonHeading from '../../src/components/canon-heading.tsx';
import CanonRow from '../../src/components/canon-row.tsx';
import CanonRows from '../../src/components/canon-rows.tsx';
import CanonSegmented from '../../src/components/canon-segmented.tsx';
import CanonSwitch from '../../src/components/canon-switch.tsx';
import { dimensionLines, sheet, type Rect } from '@canon/lib/dimension-line.ts';
import '../../../../demo-app/components/gallery/measures.css';

export const pane = 'main';
export const order = 16;

const picture = { width: 1600, height: 1200 };

const scales = [
  { title: 'Saved', before: 2_400_000, after: 1_700_000, working: false },
  { title: 'Grew', before: 2_400_000, after: 3_100_000, working: false },
  { title: 'Even', before: 2_400_000, after: 2_400_000, working: false },
  { title: 'Working', before: 2_400_000, after: 0, working: true },
  { title: 'Empty', before: 0, after: 0, working: false },
];
const titles = scales.map((scale) => scale.title);

const box = ({ x, y, width, height }: Rect) => ({
  insetInlineStart: x,
  insetBlockStart: y,
  inlineSize: width,
  blockSize: height,
});

export default function Measures() {
  const [area, setArea] = useState<Rect>({ x: 0, y: 0, width: 0, height: 0 });
  const [scale, setScale] = useState(0);
  const [blank, setBlank] = useState(false);
  const measure = useCallback((element: HTMLElement) => {
    const observer = new ResizeObserver(() =>
      setArea({
        x: element.offsetLeft,
        y: element.offsetTop,
        width: element.clientWidth,
        height: element.clientHeight,
      }),
    );
    observer.observe(element);
    return () => observer.disconnect();
  }, []);
  const frame = sheet(picture, area);
  const { across, down } = dimensionLines(frame);
  const shown = scales[scale]!;
  return (
    <>
      <CanonCanvas height={220} background="var(--canon-muted)">
        <div className="gallery-dimensions">
          <span className="gallery-dimensions-area" ref={measure} />
          {area.width > 0 && (
            <>
              <span className="gallery-dimensions-sheet" style={box(frame)} />
              <CanonDimensionLine
                pixels={picture.width}
                blank={blank}
                style={box(across)}
              />
              <CanonDimensionLine
                pixels={picture.height}
                blank={blank}
                down
                style={box(down)}
              />
            </>
          )}
        </div>
      </CanonCanvas>
      <CanonCanvas height={176}>
        <CanonCompressionScale
          before={shown.before}
          after={shown.after}
          format="JPEG"
          working={shown.working}
        />
      </CanonCanvas>
      <CanonRows framed>
        <CanonHeading text="Measures" />
        <CanonSegmented items={titles} selected={scale} onChange={setScale} />
        <CanonRow title="Blank">
          {(titleId) => (
            <CanonSwitch
              on={blank}
              onChange={setBlank}
              aria-labelledby={titleId}
            />
          )}
        </CanonRow>
      </CanonRows>
    </>
  );
}
