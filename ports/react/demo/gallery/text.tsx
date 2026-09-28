import { useMemo, useState } from 'react';
import type { GlyphKind } from '@canon/lib/glyph-rows.ts';
import CanonCanvas from '../../src/components/canon-canvas.tsx';
import CanonGlyphFlow from '../../src/components/canon-glyph-flow.tsx';
import CanonHeading from '../../src/components/canon-heading.tsx';
import CanonRows from '../../src/components/canon-rows.tsx';
import CanonTextInput from '../../src/components/canon-text-input.tsx';
import CanonTextOutput from '../../src/components/canon-text-output.tsx';
import '../../../../demo-app/components/gallery/display.css';

export const pane = 'main';
export const order = 30;

const start = 'Glyph flow';
const metrics = { height: 36, rowGap: 8, gap: 4 };
const measure = () => 28;
const kind = (c: string): GlyphKind =>
  c === '\n' ? 'newline' : /\s/.test(c) ? 'space' : 'glyph';
const isSpace = (c: string) => /\s/.test(c);

export default function Text() {
  const [text, setText] = useState(start);
  const glyphs = useMemo(() => [...text], [text]);
  return (
    <>
      <CanonCanvas height={120}>
        <CanonGlyphFlow
          glyphs={glyphs}
          metrics={metrics}
          measure={measure}
          kind={kind}
          label={text}
        >
          {(glyph) =>
            !isSpace(glyph) && <span className="gallery-glyph">{glyph}</span>
          }
        </CanonGlyphFlow>
      </CanonCanvas>
      <CanonRows framed>
        <CanonHeading text="Text input" />
        <CanonTextInput value={start} onChange={setText} />
      </CanonRows>
      <CanonTextOutput
        text={text.toUpperCase()}
        heading="Text output"
        fileName="gallery.txt"
      />
    </>
  );
}
