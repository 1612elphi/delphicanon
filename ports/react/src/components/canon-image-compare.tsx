import {
  useRef,
  useState,
  type CSSProperties,
  type HTMLAttributes,
  type KeyboardEvent,
  type MouseEvent,
  type Ref,
} from 'react';
import { compareSpring, springEasing } from '@canon/lib/motion.ts';
import { cx } from '../lib/class-names.ts';
import { ArrowLeftRight } from '../lib/control-icons.tsx';
import { useSidewaysPan } from '../lib/pans.ts';
import { useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-image-compare.css';

export interface CanonImageCompareProps extends HTMLAttributes<HTMLDivElement> {
  /** URL of the original. */
  before?: string;
  /** URL of the result. */
  after?: string;
  /** The result could not be made: the original dims and `failure` shows. */
  failed?: boolean;
  /** Shown over the original when `failed`. */
  failure?: string;
  beforeTitle?: string;
  afterTitle?: string;
  ref?: Ref<HTMLDivElement>;
}

const tapEasing = springEasing(compareSpring.damping);
const nudge = 0.1;

const clamp = (value: number) => Math.min(Math.max(value, 0), 1);

/**
 * One picture, the original on the leading side of a draggable divider and
 * the result on the other; a tap moves the divider. To assistive technology
 * it is a slider.
 */
export default function CanonImageCompare({
  before,
  after,
  failed,
  failure,
  beforeTitle = 'Before',
  afterTitle = 'After',
  className,
  style,
  ref,
  ...rest
}: CanonImageCompareProps) {
  // share of the width that shows the original
  const [split, setSplit] = useState(0.5);
  const [springs, setSprings] = useState(false);
  const dragged = useRef(false);
  const comparing = Boolean(before && after);
  const percent = Math.round(split * 100);

  const move = (element: HTMLElement, clientX: number, spring: boolean) => {
    const box = element.getBoundingClientRect();
    if (box.width <= 0 || !comparing) return;
    let share = (clientX - box.left) / box.width;
    if (getComputedStyle(element).direction === 'rtl') share = 1 - share;
    setSprings(
      spring && !window.matchMedia('(prefers-reduced-motion: reduce)').matches,
    );
    setSplit(clamp(share));
  };

  const pan = useSidewaysPan({
    onBegin: () => {
      dragged.current = true;
    },
    onMove: (event) =>
      move(event.currentTarget as HTMLElement, event.clientX, false),
  });

  const onClick = (event: MouseEvent<HTMLDivElement>) => {
    if (dragged.current) {
      dragged.current = false;
      return;
    }
    move(event.currentTarget, event.clientX, true);
  };

  const onKey = (event: KeyboardEvent<HTMLDivElement>) => {
    if (!comparing) return;
    const sign =
      getComputedStyle(event.currentTarget).direction === 'rtl' ? -1 : 1;
    const steps: Record<string, number> = {
      ArrowRight: nudge * sign,
      ArrowLeft: -nudge * sign,
      ArrowUp: nudge,
      ArrowDown: -nudge,
      Home: -1,
      End: 1,
    };
    const step = steps[event.key];
    if (step === undefined) return;
    event.preventDefault();
    setSprings(false);
    setSplit((current) => clamp(current + step));
  };

  const vars: Record<string, string | number> = {
    '--canon-compare-split': split,
  };
  if (springs)
    vars['--canon-compare-transition'] = `${compareSpring.ms}ms ${tapEasing}`;

  return (
    <div
      className={cx(
        'canon-image-compare',
        comparing && 'canon-image-compare--comparing',
        failed && 'canon-image-compare--failed',
        className,
      )}
      style={{ ...vars, ...style } as CSSProperties}
      role={comparing ? 'slider' : undefined}
      tabIndex={comparing ? 0 : undefined}
      aria-label={`${beforeTitle}, ${afterTitle}`}
      aria-valuemin={comparing ? 0 : undefined}
      aria-valuemax={comparing ? 100 : undefined}
      aria-valuenow={comparing ? percent : undefined}
      aria-valuetext={comparing ? `${percent}%` : undefined}
      ref={useRefs(pan, ref)}
      onClick={onClick}
      onKeyDown={onKey}
      {...rest}
    >
      {before && (
        <img
          className="canon-image-compare-before"
          src={before}
          alt=""
          draggable="false"
        />
      )}
      {comparing && (
        <>
          <div className="canon-image-compare-after">
            <img src={after} alt="" draggable="false" />
          </div>
          <div className="canon-image-compare-divider" />
          <div className="canon-image-compare-grip">
            <ArrowLeftRight />
          </div>
          <span className="canon-image-compare-tag canon-image-compare-tag--before">
            {beforeTitle}
          </span>
          <span className="canon-image-compare-tag canon-image-compare-tag--after">
            {afterTitle}
          </span>
        </>
      )}
      {failed && (
        <p className="canon-image-compare-failure" role="status">
          {failure}
        </p>
      )}
    </div>
  );
}
