import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  type ButtonHTMLAttributes,
  type Ref,
} from 'react';
import type { Key } from '@canon/lib/math/expression.ts';
import {
  familyOf,
  keyHeights,
  label as keyLabel,
  labelShare,
  spoken,
  type Family,
} from '@canon/lib/math/keypad.ts';
import { canvasMetrics } from '@canon/lib/math/measure.ts';
import type { Box } from '@canon/lib/math/typeset.ts';
import { repeatTiming } from './canon-button.tsx';
import CanonMathView from './canon-math-view.tsx';
import { cx } from '../lib/class-names.ts';
import { ChevronUp } from '../lib/control-icons.tsx';
import { press } from '../lib/press.ts';
import { useLatest, useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-key.css';

export interface CanonMathKeyProps extends Omit<
  ButtonHTMLAttributes<HTMLButtonElement>,
  'onClick'
> {
  /** The key typed; gives the label, the family and the spoken name. `key` in Ember, which React reserves. */
  mathKey?: Key;
  /** The letter the derivative key shows; default x. */
  variable?: string;
  /** Label size in px before `scale`; default 24, the regular key's. */
  size?: number;
  scale?: number;
  /** A label set elsewhere, instead of the key's. */
  face?: Box;
  family?: Family;
  /** Accessible name; default the key's spoken name. */
  label?: string;
  /** Marks a key that opens a submenu with a chevron. */
  menu?: boolean;
  /** Holding repeats the tap, as delete does. */
  repeats?: boolean;
  onClick?: () => void;
  ref?: Ref<HTMLButtonElement>;
}

/** Travel in px that turns a press into a drag. */
export const slop = 10;

/**
 * One key: a flush cell in its family's colours with one label, set large
 * and centred (CanonMathKeyView). A tap does one thing; a drag past the slop
 * does nothing. Outside the keypad it is the insert cell
 * (`CanonMathKeypad.cell`).
 */
export default function CanonMathKey({
  mathKey,
  variable,
  size,
  scale,
  face: given,
  family: givenFamily,
  label: givenLabel,
  menu,
  repeats,
  onClick,
  className,
  children,
  ref,
  ...rest
}: CanonMathKeyProps) {
  const stroke = useRef({ moved: false, held: false, didRepeat: false });
  const timer = useRef<number>(undefined);
  const latest = useLatest({ onClick, repeats });

  const family =
    givenFamily ?? (mathKey ? familyOf(mathKey) : ('digit' as Family));
  const face = useMemo(() => {
    if (given) return given;
    if (!mathKey) return undefined;
    const base = size ?? Math.round(keyHeights.regular * labelShare);
    return keyLabel(
      mathKey,
      variable ?? 'x',
      base * (scale ?? 1),
      canvasMetrics,
    );
  }, [given, mathKey, variable, size, scale]);
  const label =
    givenLabel ?? (mathKey ? spoken(mathKey, variable ?? 'x') : undefined);

  useEffect(() => () => window.clearTimeout(timer.current), []);

  const click = () => {
    const state = stroke.current;
    if (state.moved || state.didRepeat) {
      state.didRepeat = false;
      return;
    }
    onClick?.();
  };

  const strokes = useCallback(
    (button: HTMLButtonElement | null) => {
      if (!button) return;
      const state = stroke.current;
      let start: { x: number; y: number } | undefined;
      const letGo = () => {
        state.held = false;
        window.clearTimeout(timer.current);
      };
      const schedule = (seconds: number, count: number) => {
        window.clearTimeout(timer.current);
        timer.current = window.setTimeout(() => {
          if (!state.held) return;
          state.didRepeat = true;
          latest.current.onClick?.();
          schedule(
            count < 10 ? repeatTiming.interval : repeatTiming.fast,
            count + 1,
          );
        }, seconds * 1000);
      };
      const down = (event: PointerEvent) => {
        start = { x: event.clientX, y: event.clientY };
        state.moved = false;
        state.didRepeat = false;
        if (!latest.current.repeats || event.button !== 0) return;
        state.held = true;
        schedule(repeatTiming.delay, 0);
      };
      const move = (event: PointerEvent) => {
        if (!start || state.moved) return;
        const travel = Math.hypot(
          event.clientX - start.x,
          event.clientY - start.y,
        );
        if (travel > slop && !state.didRepeat) {
          state.moved = true;
          letGo();
        }
      };
      const ends = [
        'pointerup',
        'pointercancel',
        'lostpointercapture',
      ] as const;
      button.addEventListener('pointerdown', down);
      button.addEventListener('pointermove', move);
      ends.forEach((type) => button.addEventListener(type, letGo));
      return () => {
        letGo();
        button.removeEventListener('pointerdown', down);
        button.removeEventListener('pointermove', move);
        ends.forEach((type) => button.removeEventListener(type, letGo));
      };
    },
    [latest],
  );

  const hasBlock = children !== undefined && children !== null;
  return (
    <button
      type="button"
      className={cx('canon-math-key', `canon-math-key--${family}`, className)}
      aria-label={label}
      aria-haspopup={menu ? 'true' : undefined}
      onClick={click}
      ref={useRefs(press, strokes, ref)}
      {...rest}
    >
      <span className="canon-math-key-face">
        {hasBlock
          ? children
          : face && <CanonMathView box={face} mono aria-hidden="true" />}
        {menu && (
          <span className="canon-math-key-chevron">
            <ChevronUp />
          </span>
        )}
      </span>
    </button>
  );
}
