import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type CSSProperties,
  type HTMLAttributes,
  type ReactNode,
  type Ref,
  type RefObject,
} from 'react';
import {
  advance,
  detent,
  drum,
  goal,
  isSettled,
  placement,
  tappedRows,
  wrapped,
  type DetentMotion,
  type DetentRange,
} from '@canon/lib/detent-wheel.ts';
import { cx } from '../lib/class-names.ts';
import { useGrabPan } from '../lib/pans.ts';
import { useLatest, useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-detent-wheel.css';

export interface CanonDetentWheelProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'children' | 'onSelect'
> {
  count: number;
  /** The centred row. A change turns the wheel there the shorter way round. */
  selected: number;
  /** Default 40. */
  rowHeight?: number;
  /** The centred row changed, by a drag, a fling, a tap, the wheel or the keys, once per row crossed. */
  onSelect?: (index: number) => void;
  /** Accessible reading of a row. */
  text?: (index: number) => string;
  label?: string;
  labelledBy?: string;
  /** Paints one row: its index and `focus`, 1 on the centre line and 0 a row or more away. */
  children?: (index: number, focus: number) => ReactNode;
  ref?: Ref<HTMLDivElement>;
}

/** Pointer travel in px under which a release is a tap. */
const tapSlop = 6;
/** Wheel events further apart than this end a wheel turn. */
const wheelRestMs = 120;

interface WheelProps {
  count: number;
  rowHeight: number;
  onSelect?: (index: number) => void;
}

function clampIndex(index: number, count: number) {
  return count === 0 ? 0 : Math.min(Math.max(index, 0), count - 1);
}

function reducedMotion() {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

/** The wheel's motion, outside React state: frames, drags and the wheel read and write it at once. */
class Turning {
  motion: DetentMotion;
  count: number;
  asked: number;
  selected: number;
  height = 0;
  frame?: number;
  last = 0;
  dragging = false;
  drag = { startY: 0, lastY: 0, travel: 0, samples: [] as [number, number][] };
  wheelTimer?: number;

  constructor(
    selected: number,
    readonly props: RefObject<WheelProps>,
    readonly show: (position: number, selected: number) => void,
  ) {
    this.count = props.current.count;
    this.asked = selected;
    this.selected = selected;
    this.motion = { position: selected, velocity: 0, target: selected };
  }

  get geometry() {
    return drum(this.height, this.props.current.rowHeight);
  }

  get loops() {
    return this.props.current.count > this.geometry.fitting;
  }

  get range(): DetentRange {
    return this.loops
      ? undefined
      : [0, Math.max(this.props.current.count - 1, 0)];
  }

  place(position: number) {
    const { count, onSelect } = this.props.current;
    const nearest = wrapped(Math.round(position), count);
    const changed = count !== 0 && nearest !== this.selected;
    if (changed) {
      this.selected = nearest;
      this.asked = nearest;
    }
    this.show(position, this.selected);
    if (changed) onSelect?.(nearest);
  }

  run() {
    if (this.frame !== undefined) return;
    this.last = performance.now();
    const frame = (now: number) => {
      const seconds = Math.min((now - this.last) / 1000, 1 / 30);
      this.last = now;
      this.motion = advance(this.motion, seconds, this.range);
      this.place(this.motion.position);
      if (isSettled(this.motion)) this.frame = undefined;
      else this.frame = requestAnimationFrame(frame);
    };
    this.frame = requestAnimationFrame(frame);
  }

  stop() {
    if (this.frame !== undefined) cancelAnimationFrame(this.frame);
    this.frame = undefined;
  }

  /** Turns to `index`, the shorter way round when the wheel loops. */
  select(index: number, animated: boolean) {
    const { count } = this.props.current;
    if (count === 0) return;
    const to = goal(this.motion.position, index, count, this.loops);
    if (animated && !reducedMotion()) {
      this.motion = { ...this.motion, target: to };
      this.run();
    } else {
      this.stop();
      this.motion = { position: to, velocity: 0, target: to };
      this.place(to);
    }
  }

  /** Moves by `rows` of drag, pulled short past the ends. */
  pull(rows: number) {
    const { range } = this;
    const { position } = this.motion;
    const outside = range && (position < range[0] || position > range[1]);
    this.motion = {
      position: position + (outside ? rows * detent.rubber : rows),
      velocity: 0,
    };
    this.place(this.motion.position);
  }

  release(velocity: number) {
    this.motion = { ...this.motion, velocity, target: undefined };
    this.run();
  }

  /** A new `count` snaps to `selected`; a new `selected` turns there. */
  follow(count: number, selected: number) {
    if (count !== this.count) {
      this.count = count;
      this.asked = selected;
      const index = clampIndex(selected, count);
      this.stop();
      this.selected = index;
      this.motion = { position: index, velocity: 0, target: index };
      this.show(index, index);
    } else if (selected !== this.asked) {
      this.asked = selected;
      if (selected !== this.selected && !this.dragging)
        this.select(clampIndex(selected, count), true);
    }
  }

  wheel = (event: WheelEvent) => {
    const { count, rowHeight } = this.props.current;
    if (count === 0) return;
    event.preventDefault();
    this.stop();
    this.pull(
      event.deltaMode === WheelEvent.DOM_DELTA_PIXEL
        ? event.deltaY / rowHeight
        : Math.sign(event.deltaY),
    );
    window.clearTimeout(this.wheelTimer);
    this.wheelTimer = window.setTimeout(() => this.release(0), wheelRestMs);
  };

  begin = (event: PointerEvent) => {
    this.stop();
    this.dragging = true;
    this.drag = {
      startY: event.clientY,
      lastY: event.clientY,
      travel: 0,
      samples: [[event.timeStamp, event.clientY]],
    };
  };

  move = (event: PointerEvent) => {
    const drag = this.drag;
    const dy = event.clientY - drag.lastY;
    drag.lastY = event.clientY;
    drag.travel = Math.max(drag.travel, Math.abs(event.clientY - drag.startY));
    drag.samples = [
      ...drag.samples.filter(([time]) => event.timeStamp - time < 100),
      [event.timeStamp, event.clientY],
    ];
    this.pull(-dy / this.props.current.rowHeight);
  };

  end = (event: PointerEvent) => {
    this.dragging = false;
    const drag = this.drag;
    if (drag.travel < tapSlop) {
      this.tap(event);
      return;
    }
    const [first] = drag.samples;
    const seconds = first ? (event.timeStamp - first[0]) / 1000 : 0;
    const pxPerSecond =
      first && seconds > 0 ? (event.clientY - first[1]) / seconds : 0;
    const speed =
      (-pxPerSecond / this.props.current.rowHeight) * detent.flingCarry;
    this.release(
      Math.min(Math.max(speed, -detent.flingLimit), detent.flingLimit),
    );
  };

  tap(event: PointerEvent) {
    const box = (event.currentTarget as HTMLElement).getBoundingClientRect();
    const { radius, step } = this.geometry;
    const rows = tappedRows(
      event.clientY - (box.top + box.height / 2),
      radius,
      step,
    );
    let to = Math.round(this.motion.position) + rows;
    const { range } = this;
    if (range) to = Math.min(Math.max(to, range[0]), range[1]);
    this.motion = { ...this.motion, target: to };
    this.run();
  }

  key = (event: KeyboardEvent) => {
    const { count } = this.props.current;
    if (count === 0) return;
    const last = count - 1;
    const next: Record<string, number> = {
      ArrowDown: this.selected + 1,
      ArrowRight: this.selected + 1,
      ArrowUp: this.selected - 1,
      ArrowLeft: this.selected - 1,
      Home: 0,
      End: last,
    };
    const to = next[event.key];
    if (to === undefined) return;
    event.preventDefault();
    if (!this.loops && (to < 0 || to > last)) return;
    this.select(wrapped(to, count), true);
  };
}

/**
 * Rows on a drum, turned by a vertical drag or the mouse wheel, with inertia;
 * it comes to rest on a row, and the centred row is the selection. Rows
 * flatten and fade with their angle from the centre. It loops when there are
 * more rows than fit; otherwise the ends pull back like rubber.
 */
export default function CanonDetentWheel({
  count,
  selected: asked,
  rowHeight = 40,
  onSelect,
  text,
  label,
  labelledBy,
  children,
  className,
  style,
  ref,
  ...rest
}: CanonDetentWheelProps) {
  const [shown, setShown] = useState(() => {
    const index = clampIndex(asked, count);
    return { position: index, selected: index };
  });
  const [height, setHeight] = useState(0);
  const props = useLatest<WheelProps>({ count, rowHeight, onSelect });
  const turning = useRef<Turning>(null);
  const start = shown.selected;
  const wheel = useCallback(
    () =>
      (turning.current ??= new Turning(start, props, (position, selected) =>
        setShown({ position, selected }),
      )),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  );

  useEffect(() => wheel().follow(count, asked), [wheel, count, asked]);

  const measure = useCallback(
    (element: HTMLDivElement) => {
      const turns = wheel();
      const observer = new ResizeObserver(([entry]) => {
        turns.height = entry?.contentRect.height ?? 0;
        setHeight(turns.height);
      });
      observer.observe(element);
      element.addEventListener('wheel', turns.wheel, { passive: false });
      return () => {
        observer.disconnect();
        element.removeEventListener('wheel', turns.wheel);
        turns.stop();
        window.clearTimeout(turns.wheelTimer);
      };
    },
    [wheel],
  );

  const pan = useGrabPan({
    grabs: () => count > 0,
    onBegin: (event) => wheel().begin(event),
    onMove: (event) => wheel().move(event),
    onEnd: (event) => wheel().end(event),
  });

  const { position, selected } = shown;
  const { radius, step, fitting } = drum(height, rowHeight);
  const loops = count > fitting;
  const rows = [];
  if (count > 0 && height > 0) {
    const half = Math.floor(detent.reach / step) + 1;
    const centre = Math.round(position);
    for (let index = centre - half; index <= centre + half; index++) {
      if (!loops && (index < 0 || index >= count)) continue;
      const offset = index - position;
      if (Math.abs(offset) * step > detent.reach) continue;
      const { y, scaleY, opacity, focus } = placement(offset, step, radius);
      rows.push(
        <div
          key={index}
          className="canon-detent-wheel-slot"
          style={{
            transform: `translateY(${y}px) scaleY(${scaleY})`,
            opacity,
          }}
          aria-hidden="true"
        >
          {children?.(wrapped(index, count), focus)}
        </div>,
      );
    }
  }

  return (
    <div
      className={cx('canon-detent-wheel', className)}
      style={
        { '--canon-detent-row': `${rowHeight}px`, ...style } as CSSProperties
      }
      role="slider"
      tabIndex={0}
      aria-orientation="vertical"
      aria-valuemin={0}
      aria-valuemax={Math.max(count - 1, 0)}
      aria-valuenow={selected}
      aria-valuetext={count > 0 ? text?.(selected) : undefined}
      aria-label={label}
      aria-labelledby={labelledBy}
      onKeyDown={(event) => wheel().key(event.nativeEvent)}
      ref={useRefs(measure, pan, ref)}
      {...rest}
    >
      {rows}
    </div>
  );
}
