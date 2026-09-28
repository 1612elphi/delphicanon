import { motion, pressedTransform, springEasing } from '@canon/lib/motion.ts';

const release = springEasing(motion.releaseDamping);

function still(): boolean {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

/**
 * A ref callback: tilts the element under the pointer while pressed and
 * springs it back on release (CanonMotion.press / release).
 */
export function press(element: HTMLElement | null): (() => void) | undefined {
  if (!element) return;
  let down = false;
  let settle: number | undefined;

  const disabled = () => element.matches(':disabled, [aria-disabled="true"]');
  const pointIn = (event: PointerEvent) => {
    const box = element.getBoundingClientRect();
    return { x: event.clientX - box.left, y: event.clientY - box.top };
  };
  const pose = (point: { x: number; y: number } | undefined, ms: number) => {
    element.style.transition = `transform ${ms}ms ease-out`;
    element.style.transform = pressedTransform(
      element.offsetWidth,
      element.offsetHeight,
      point,
    );
  };

  const onDown = (event: PointerEvent) => {
    if (disabled() || still() || event.button !== 0) return;
    window.clearTimeout(settle);
    down = true;
    pose(pointIn(event), motion.pressMs);
  };
  const onMove = (event: PointerEvent) => {
    if (!down) return;
    pose(pointIn(event), motion.followMs);
  };
  // fast tap reaches the pose before the spring
  const onUp = (event: PointerEvent) => {
    if (!down) return;
    down = false;
    pose(
      event.type === 'pointerup' ? pointIn(event) : undefined,
      motion.pressMs,
    );
    settle = window.setTimeout(() => {
      element.style.transition = `transform ${motion.releaseMs}ms ${release}`;
      element.style.transform = '';
    }, motion.pressMs);
  };

  element.addEventListener('pointerdown', onDown);
  element.addEventListener('pointermove', onMove);
  element.addEventListener('pointerup', onUp);
  element.addEventListener('pointercancel', onUp);
  element.addEventListener('pointerleave', onUp);
  return () => {
    window.clearTimeout(settle);
    element.removeEventListener('pointerdown', onDown);
    element.removeEventListener('pointermove', onMove);
    element.removeEventListener('pointerup', onUp);
    element.removeEventListener('pointercancel', onUp);
    element.removeEventListener('pointerleave', onUp);
  };
}
