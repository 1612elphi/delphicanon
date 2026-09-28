import {
  useState,
  type CSSProperties,
  type HTMLAttributes,
  type Ref,
} from 'react';
import { canvasMetrics } from '@canon/lib/math/measure.ts';
import { Typesetter } from '@canon/lib/math/typeset.ts';
import CanonMathView from './canon-math-view.tsx';
import { cx } from '../lib/class-names.ts';
import { press } from '../lib/press.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-tabs.css';

export interface CanonMathTabsProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'onSelect'
> {
  /** The page position, fractional mid-swipe. */
  progress: number;
  onSelect?: (page: number) => void;
  ref?: Ref<HTMLDivElement>;
}

const accents = [
  'var(--canon-foreground)',
  'var(--canon-math-green)',
  'var(--canon-math-blue)',
  'var(--canon-math-clay)',
];
const names = ['Numbers', 'Functions', 'Calculus', 'Letters'];
export const lampHeight = 3;

function faces() {
  const setter = new Typesetter(canvasMetrics, 18);
  const functions = setter
    .text('f', { italic: true })
    .append(setter.parens(setter.text('x', { italic: true }), 0), 1);
  const calculus = setter.text('∫').append(setter.text('Σ'), 3);
  return [
    setter.text('123'),
    functions,
    calculus,
    setter.text('xyz', { italic: true }),
  ];
}

/**
 * The pages' names as maths, each lit in its page's colour as the page comes
 * into view, over a lamp that slides and changes colour with the swipe.
 */
export default function CanonMathTabs({
  progress: given,
  onSelect,
  className,
  ...rest
}: CanonMathTabsProps) {
  const [tabFaces] = useState(faces);
  const progress = Math.min(Math.max(given, 0), names.length - 1);

  const low = Math.floor(progress);
  const high = Math.min(low + 1, names.length - 1);
  const share = progress - low;
  // lamp narrows mid-swipe
  const lampWidth = 0.62 * (1 - 0.35 * Math.sin(Math.PI * share));

  return (
    <div className={cx('canon-math-tabs', className)} {...rest}>
      {tabFaces.map((face, index) => {
        const near = Math.max(0, 1 - Math.abs(progress - index));
        return (
          <button
            key={index}
            type="button"
            className="canon-math-tab"
            aria-label={names[index]}
            aria-current={near > 0.5 ? 'true' : undefined}
            style={{
              color: `color-mix(in srgb, var(--canon-muted-foreground), ${accents[index]} ${Math.round(near * 100)}%)`,
            }}
            ref={press}
            onClick={() => onSelect?.(index)}
          >
            <CanonMathView box={face} mono aria-hidden="true" />
          </button>
        );
      })}
      <span
        className="canon-math-tabs-lamp"
        style={
          {
            '--canon-math-progress': progress,
            '--canon-math-lamp': lampWidth,
            background: `color-mix(in srgb, ${accents[low]}, ${accents[high]} ${Math.round(share * 100)}%)`,
          } as CSSProperties
        }
      />
    </div>
  );
}
