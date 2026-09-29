import {
  useCallback,
  useState,
  type CSSProperties,
  type HTMLAttributes,
  type Ref,
} from 'react';
import { capture } from '@canon/lib/motion.ts';
import type { Key } from '@canon/lib/math/expression.ts';
import CanonButton from './canon-button.tsx';
import { cx } from '../lib/class-names.ts';
import { useLatest } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-rail.css';

export interface CanonMathRailProps extends HTMLAttributes<HTMLDivElement> {
  /** Moves the caret; false when it could not move. */
  onStep?: (key: Key) => boolean;
  short?: boolean;
  ref?: Ref<HTMLDivElement>;
}

export const railHeights = { regular: 44, short: 38 };
/** Sideways drag, in px, per caret place. */
export const stride = 16;
export const arrowWidth = 50;

const chevron = (d: string) => (
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d={d} />
  </svg>
);

const arrows = [
  { key: { kind: 'left' }, label: 'Left', icon: chevron('m15 18-6-6 6-6') },
  { key: { kind: 'up' }, label: 'Up', icon: chevron('m18 15-6-6-6 6') },
  { key: { kind: 'down' }, label: 'Down', icon: chevron('m6 9 6 6 6-6') },
  { key: { kind: 'right' }, label: 'Right', icon: chevron('m9 18 6-6-6-6') },
] as const;

/**
 * The caret's controls, under the expression: ribs that slide with a
 * sideways drag, one caret place per stride, then the four arrow keys.
 */
export default function CanonMathRail({
  onStep,
  short,
  className,
  style,
  ...rest
}: CanonMathRailProps) {
  const [phase, setPhase] = useState(0);
  const latest = useLatest(onStep);

  const drag = useCallback(
    (ribs: HTMLDivElement | null) => {
      if (!ribs) return;
      const step = (key: Key) => latest.current?.(key) ?? false;
      let last = 0;
      let stepped = 0;
      let start: number | undefined;
      const down = (event: PointerEvent) => {
        if (event.button !== 0) return;
        event.stopPropagation();
        capture(ribs, event.pointerId);
        start = event.clientX;
        last = 0;
        stepped = 0;
      };
      const move = (event: PointerEvent) => {
        if (start === undefined) return;
        const x = event.clientX - start;
        const delta = x - last;
        setPhase((phase) => phase + delta);
        last = x;
        while (x - stepped > stride) {
          stepped += stride;
          step({ kind: 'right' });
        }
        while (x - stepped < -stride) {
          stepped -= stride;
          step({ kind: 'left' });
        }
      };
      const up = () => (start = undefined);
      ribs.addEventListener('pointerdown', down);
      ribs.addEventListener('pointermove', move);
      ribs.addEventListener('pointerup', up);
      ribs.addEventListener('pointercancel', up);
      return () => {
        ribs.removeEventListener('pointerdown', down);
        ribs.removeEventListener('pointermove', move);
        ribs.removeEventListener('pointerup', up);
        ribs.removeEventListener('pointercancel', up);
      };
    },
    [latest],
  );

  return (
    <div
      className={cx('canon-math-rail', className)}
      style={
        {
          '--canon-math-rail-height': `${short ? railHeights.short : railHeights.regular}px`,
          '--canon-math-arrow-width': `${arrowWidth}px`,
          ...style,
        } as CSSProperties
      }
      {...rest}
    >
      <div
        className="canon-math-rail-ribs"
        style={{ '--canon-math-rail-phase': `${phase}px` } as CSSProperties}
        aria-hidden="true"
        ref={drag}
      />
      {arrows.map((arrow) => (
        <CanonButton
          key={arrow.label}
          kind="cell"
          icon={arrow.icon}
          label={arrow.label}
          repeats
          onClick={() => onStep?.(arrow.key)}
        />
      ))}
    </div>
  );
}
