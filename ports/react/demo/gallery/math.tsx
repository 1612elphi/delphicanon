import { useState } from 'react';
import CanonButton from '../../src/components/canon-button.tsx';
import CanonCanvas from '../../src/components/canon-canvas.tsx';
import CanonGrid from '../../src/components/canon-grid.tsx';
import CanonHeading from '../../src/components/canon-heading.tsx';
import CanonMathField, {
  CanonMathFieldHandle,
} from '../../src/components/canon-math-field.tsx';
import CanonMathKey from '../../src/components/canon-math-key.tsx';
import CanonMathKeypad from '../../src/components/canon-math-keypad.tsx';
import CanonMathView from '../../src/components/canon-math-view.tsx';
import CanonRows from '../../src/components/canon-rows.tsx';
import type { Key } from '@canon/lib/math/expression.ts';

export const pane = 'main';
export const order = 30;

const inserts: Key[] = [
  { kind: 'fraction' },
  { kind: 'power' },
  { kind: 'root' },
  { kind: 'symbol', symbol: '×' },
];
const morphs = ['(x+1)^2', 'x^2+2*x+1', '(x+1)*(x+1)'];
const views = [
  'sqrt(x^2+1)/(2*x)',
  'defint(sin(x)^2,0,pi,x)',
  'sum(k^2,k,1,n)',
];

export default function MathGroup() {
  const [handle] = useState(() => new CanonMathFieldHandle());
  const [morph, setMorph] = useState(0);

  return (
    <>
      <CanonRows framed>
        <CanonHeading text="Maths input" />
        <CanonMathField
          text="(x+1)^2/2"
          placeholder="x^2 - 4"
          handle={handle}
        />
        <CanonMathField variable="t" placeholder="sin(t)" />
        <CanonGrid columns={4}>
          {inserts.map((key, i) => (
            <CanonMathKey
              key={i}
              mathKey={key}
              onClick={() => handle.edit([key])}
            />
          ))}
        </CanonGrid>
        <CanonHeading text="Maths view" />
        <div
          style={{
            display: 'flex',
            flexWrap: 'wrap',
            gap: 24,
            alignItems: 'center',
            justifyContent: 'space-around',
            padding: 16,
            background: 'var(--canon-card)',
          }}
        >
          {views.map((text) => (
            <CanonMathView key={text} text={text} size={22} />
          ))}
          <CanonMathView text="b*c^(-1)+(1/2)*x^(-1/2)" presents />
        </div>
      </CanonRows>
      <CanonCanvas height={140}>
        <CanonMathView
          text={morphs[morph % morphs.length]}
          size={34}
          morphs
          style={{ blockSize: '100%' }}
        />
      </CanonCanvas>
      <CanonRows framed>
        <CanonButton text="Morph" onClick={() => setMorph(morph + 1)} />
        <CanonHeading text="Maths keypad" />
        <CanonMathKeypad variable="t" />
      </CanonRows>
    </>
  );
}
