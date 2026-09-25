/** Press and release feel shared by every canon control (CanonMotion). */
export const motion = {
  pressScale: 0.97,
  /** Sink in px at the edge of a square control of the same area. */
  tiltDepth: 11,
  maxTiltDegrees: 22,
  perspective: 600,
  pressMs: 80,
  releaseMs: 450,
  releaseDamping: 0.45,
  /** Tilt while held follows the pointer this fast. */
  followMs: 50,
} as const;

/**
 * Transform for a control pressed at (x, y) in its own box; no point presses
 * the centre with no lean. The edge under the pointer sinks.
 */
export function pressedTransform(
  width: number,
  height: number,
  point?: { x: number; y: number },
): string {
  const scale = `scale(${motion.pressScale})`;
  if (!point) return `perspective(${motion.perspective}px) ${scale}`;
  const halfW = Math.max(width / 2, 1);
  const halfH = Math.max(height / 2, 1);
  const clamp = (v: number) => Math.min(Math.max(v, -1), 1);
  const x = clamp((point.x - halfW) / halfW);
  const y = clamp((point.y - halfH) / halfH);
  const angle = Math.min(
    (motion.maxTiltDegrees * Math.PI) / 180,
    Math.asin(Math.min(1, motion.tiltDepth / Math.sqrt(halfW * halfH))),
  );
  return `perspective(${motion.perspective}px) rotateY(${round(x * angle)}rad) rotateX(${round(-y * angle)}rad) ${scale}`;
}

/**
 * A CSS linear() easing for a spring from rest that settles within the
 * animation's duration, as UIView's usingSpringWithDamping does.
 */
export function springEasing(damping: number, samples = 40): string {
  // ponytail: settle threshold 1 %, UIKit's exact constant is not published
  const omega = Math.log(100) / damping;
  const damped = omega * Math.sqrt(1 - damping * damping);
  const points = Array.from({ length: samples + 1 }, (_, i) => {
    if (i === samples) return 1;
    const t = i / samples;
    const decay = Math.exp(-damping * omega * t);
    return (
      1 -
      decay *
        (Math.cos(damped * t) +
          ((damping * omega) / damped) * Math.sin(damped * t))
    );
  });
  return `linear(${points.map(round).join(', ')})`;
}

function round(value: number): number {
  return Math.round(value * 10000) / 10000;
}
