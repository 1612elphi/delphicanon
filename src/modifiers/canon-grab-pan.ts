import { modifier } from 'ember-modifier';
import { capture } from '../lib/motion.ts';
import type { PanHandlers } from './canon-sideways-pan.ts';

export interface GrabPanHandlers extends PanHandlers {
  /** Whether a drag may begin at this point, in the element's own box. */
  grabs: (point: { x: number; y: number }) => boolean;
}

/**
 * A drag in any direction that begins only on a handle (CanonGrabPan). A
 * touch that lands on a handle does not scroll the page; one anywhere else
 * does.
 */
export default modifier(
  (
    element: HTMLElement,
    _: [],
    { grabs, onBegin, onMove, onEnd }: GrabPanHandlers,
  ) => {
    let pointer: number | undefined;

    const local = (x: number, y: number) => {
      const box = element.getBoundingClientRect();
      return { x: x - box.left, y: y - box.top };
    };
    // touch-action is fixed per element, so a handle's touch cancels scrolling here
    const onTouch = (event: TouchEvent) => {
      const touch = event.touches[0];
      if (
        event.touches.length === 1 &&
        touch &&
        grabs(local(touch.clientX, touch.clientY))
      )
        event.preventDefault();
    };
    const onDown = (event: PointerEvent) => {
      if (pointer !== undefined || event.button !== 0) return;
      if (!grabs(local(event.clientX, event.clientY))) return;
      pointer = event.pointerId;
      capture(element, event.pointerId);
      onBegin?.(event);
    };
    const onPointerMove = (event: PointerEvent) => {
      if (event.pointerId === pointer) onMove?.(event);
    };
    const onUp = (event: PointerEvent) => {
      if (event.pointerId !== pointer) return;
      pointer = undefined;
      onEnd?.(event);
    };

    element.addEventListener('touchstart', onTouch, { passive: false });
    element.addEventListener('pointerdown', onDown);
    element.addEventListener('pointermove', onPointerMove);
    element.addEventListener('pointerup', onUp);
    element.addEventListener('pointercancel', onUp);
    return () => {
      element.removeEventListener('touchstart', onTouch);
      element.removeEventListener('pointerdown', onDown);
      element.removeEventListener('pointermove', onPointerMove);
      element.removeEventListener('pointerup', onUp);
      element.removeEventListener('pointercancel', onUp);
    };
  },
);
