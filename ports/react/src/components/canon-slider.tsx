import {
  useCallback,
  useRef,
  useState,
  type CSSProperties,
  type HTMLAttributes,
  type Ref,
} from 'react';
import { flushSync } from 'react-dom';
import { capture } from '@canon/lib/motion.ts';
import { clamp, dragSpeed, snap } from '@canon/lib/number.ts';
import { cx } from '../lib/class-names.ts';
import { useLatest, useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-slider.css';

export interface CanonSliderProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'onChange' | 'children'
> {
  value: number;
  /** Default 0. A new range clamps the value without calling onChange. */
  min?: number;
  /** Default 1. */
  max?: number;
  /** Snaps the value to multiples of this above `min`. */
  step?: number;
  /** Text of the readout cell; default a percentage of 0 to 1. */
  readout?: (value: number) => string;
  /** Fills from the trailing edge towards the leading one: for amounts that count back from an end. */
  fillsFromTrailing?: boolean;
  labelledBy?: string;
  label?: string;
  /** `dragging` is true for a sideways drag, false for a tap or a key. */
  onChange?: (value: number, dragging: boolean) => void;
  ref?: Ref<HTMLDivElement>;
}

const percent = (value: number) => `${Math.round(value * 100)}%`;

/**
 * Square slider with a readout cell. A tap sets the value; a sideways drag
 * moves it, finer the further the pointer is pulled from the track.
 */
export default function CanonSlider({
  value: valueArg,
  min = 0,
  max = 1,
  step,
  readout = percent,
  fillsFromTrailing,
  labelledBy,
  label,
  onChange,
  className,
  style,
  ref,
  ...rest
}: CanonSliderProps) {
  const [held, setHeld] = useState<{ value: number; over: number }>();
  const dragging = useRef(false);
  const span = max - min;
  const value = clamp(
    held && held.over === valueArg ? held.value : valueArg,
    min,
    max,
  );
  const text = readout(value);
  const fraction = span > 0 ? (value - min) / span : 0;

  const apply = (raw: number) => {
    const next = snap(raw, min, max, step);
    if (next === value) return;
    setHeld({ value: next, over: valueArg });
    onChange?.(next, dragging.current);
  };
  const latest = useLatest({ apply, min, span, fillsFromTrailing });

  const drag = useCallback(
    (slider: HTMLDivElement) => {
      const track = slider.querySelector<HTMLElement>('.canon-slider-track')!;
      let pointer: number | undefined;
      let start = { x: 0, y: 0 };
      let lastX = 0;
      let dragged = 0;

      // pointer events come faster than React renders; each apply compares with the last
      const applyNow = (raw: number) =>
        flushSync(() => latest.current.apply(raw));
      const backwards = () =>
        (getComputedStyle(slider).direction === 'rtl') !==
        (latest.current.fillsFromTrailing ?? false);
      const position = (x: number) => {
        const box = track.getBoundingClientRect();
        if (box.width <= 0) return undefined;
        const unit = clamp((x - box.left) / box.width, 0, 1);
        const { min, span } = latest.current;
        return min + (backwards() ? 1 - unit : unit) * span;
      };

      const down = (event: PointerEvent) => {
        if (event.button !== 0) return;
        pointer = event.pointerId;
        start = { x: event.clientX, y: event.clientY };
        dragging.current = false;
        capture(slider, pointer);
        slider.dataset['active'] = '';
      };
      const move = (event: PointerEvent) => {
        if (event.pointerId !== pointer) return;
        if (!dragging.current) {
          const dx = Math.abs(event.clientX - start.x);
          const at = position(event.clientX);
          if (
            dx <= 4 ||
            dx <= Math.abs(event.clientY - start.y) ||
            at === undefined
          )
            return;
          // absolute first, then relative
          dragging.current = true;
          dragged = at;
          lastX = event.clientX;
          applyNow(dragged);
          return;
        }
        const { min, span } = latest.current;
        const box = slider.getBoundingClientRect();
        const speed = dragSpeed(
          Math.abs(event.clientY - (box.top + box.height / 2)),
        );
        const width = Math.max(1, track.getBoundingClientRect().width);
        const delta = ((event.clientX - lastX) / width) * span * speed;
        lastX = event.clientX;
        dragged = clamp(
          dragged + (backwards() ? -delta : delta),
          min,
          min + span,
        );
        applyNow(dragged);
      };
      const end = (event: PointerEvent) => {
        if (event.pointerId !== pointer) return;
        if (event.type === 'pointerup' && !dragging.current) {
          const box = track.getBoundingClientRect();
          const inside =
            event.clientX >= box.left &&
            event.clientX <= box.right &&
            event.clientY >= box.top &&
            event.clientY <= box.bottom;
          const at = position(event.clientX);
          if (inside && at !== undefined) applyNow(at);
        }
        pointer = undefined;
        dragging.current = false;
        delete slider.dataset['active'];
      };

      slider.addEventListener('pointerdown', down);
      slider.addEventListener('pointermove', move);
      slider.addEventListener('pointerup', end);
      slider.addEventListener('pointercancel', end);
      return () => {
        slider.removeEventListener('pointerdown', down);
        slider.removeEventListener('pointermove', move);
        slider.removeEventListener('pointerup', end);
        slider.removeEventListener('pointercancel', end);
      };
    },
    [latest],
  );

  return (
    <div
      className={cx(
        'canon-slider',
        fillsFromTrailing && 'canon-slider--trailing',
        className,
      )}
      role="slider"
      tabIndex={0}
      aria-labelledby={labelledBy}
      aria-label={label}
      aria-valuemin={min}
      aria-valuemax={max}
      aria-valuenow={value}
      aria-valuetext={text}
      style={{ '--canon-slider-fraction': fraction, ...style } as CSSProperties}
      {...rest}
      ref={useRefs(drag, ref)}
      onKeyDown={(event) => {
        const by = step ?? span / 20;
        const next = (
          {
            ArrowRight: value + by,
            ArrowUp: value + by,
            ArrowLeft: value - by,
            ArrowDown: value - by,
            Home: min,
            End: max,
          } as Record<string, number>
        )[event.key];
        if (next === undefined) return;
        event.preventDefault();
        apply(next);
      }}
    >
      <div className="canon-slider-track">
        <div className="canon-slider-fill" />
        <div className="canon-slider-marker" />
      </div>
      <div className="canon-slider-readout" aria-hidden="true">
        {text}
      </div>
    </div>
  );
}
