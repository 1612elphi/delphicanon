/** CanonDetentWheel's feel; positions are in rows, speeds in rows per second. */
export const detent = {
  /** 1/s, exponential decay of a fling. */
  friction: 4.5,
  /** Share of the pointer's speed a release keeps, and its cap. */
  flingCarry: 0.85,
  flingLimit: 36,
  /** Below this speed the nearest row catches the wheel. */
  catchSpeed: 2.5,
  /** Seconds of travel looked ahead when choosing the row to catch. */
  catchLead: 0.12,
  /** Detent spring; about 2 % overshoot. */
  stiffness: 320,
  damping: 28,
  /** Share of a drag that moves the wheel past its ends. */
  rubber: 0.3,
  /** Furthest angle a row is drawn at, radians from the centre. */
  reach: (Math.PI / 2) * 0.94,
} as const;

export interface DetentMotion {
  position: number;
  velocity: number;
  /** The row a spring is pulling to; undefined while coasting. */
  target?: number;
}

/** Row indices the wheel may rest on, or undefined when it loops. */
export type DetentRange = readonly [number, number] | undefined;

export function isSettled(motion: DetentMotion): boolean {
  return motion.target === motion.position && motion.velocity === 0;
}

function clamped(value: number, range: DetentRange): number {
  return range ? Math.min(Math.max(value, range[0]), range[1]) : value;
}

/** One frame of a released wheel: coast under friction, then a spring onto the caught row. */
export function advance(
  motion: DetentMotion,
  seconds: number,
  range: DetentRange,
): DetentMotion {
  const next = { ...motion };
  if (next.target !== undefined) {
    const pull =
      -detent.stiffness * (next.position - next.target) -
      detent.damping * next.velocity;
    next.velocity += pull * seconds;
    next.position += next.velocity * seconds;
    if (
      Math.abs(next.position - next.target) < 0.001 &&
      Math.abs(next.velocity) < 0.02
    ) {
      next.position = next.target;
      next.velocity = 0;
    }
  } else {
    next.position += next.velocity * seconds;
    next.velocity *= Math.exp(-detent.friction * seconds);
    if (range && (next.position < range[0] || next.position > range[1])) {
      next.target = clamped(Math.round(next.position), range);
    } else if (Math.abs(next.velocity) < detent.catchSpeed) {
      next.target = clamped(
        Math.round(next.position + next.velocity * detent.catchLead),
        range,
      );
    }
  }
  return next;
}

export function wrapped(index: number, count: number): number {
  return count === 0 ? 0 : ((index % count) + count) % count;
}

/** The drum's radius and the angle between rows, for a wheel `height` tall. */
export function drum(height: number, rowHeight: number) {
  const radius = Math.max(height / 2, rowHeight);
  const step = rowHeight / radius;
  /** Rows that fit on the visible half-turn; with more the wheel loops. */
  const fitting = 2 * Math.floor(detent.reach / step) + 1;
  return { radius, step, fitting };
}

/** Where a row `offset` rows from the centre is drawn. */
export function placement(offset: number, step: number, radius: number) {
  const angle = offset * step;
  const lean = Math.cos(angle);
  return {
    y: radius * Math.sin(angle),
    scaleY: Math.max(lean, 0.01),
    opacity: Math.max(lean, 0) ** 1.4,
    focus: Math.max(0, 1 - Math.abs(offset)),
  };
}

/** The position that shows `index`, the shorter way round from `position` when the wheel loops. */
export function goal(
  position: number,
  index: number,
  count: number,
  loops: boolean,
): number {
  if (!loops) return index;
  const here = Math.round(position);
  const ahead = wrapped(index - here, count);
  return here + (ahead > count / 2 ? ahead - count : ahead);
}

/** Rows between the centre and a tap `lift` px below it. */
export function tappedRows(lift: number, radius: number, step: number): number {
  // || 0 turns -0 into 0
  return (
    Math.round(Math.asin(Math.min(Math.max(lift / radius, -1), 1)) / step) || 0
  );
}
