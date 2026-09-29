import { capture } from '@canon/lib/motion.ts';
import { elementDirective } from './directive.ts';
import type { PanHandlers } from './sideways-pan.ts';

export interface GrabPanHandlers extends PanHandlers {
  /** Whether a drag may begin at this point, in the element's own box. */
  grabs: (point: { x: number; y: number }) => boolean;
}

/**
 * A drag in any direction that begins only on a handle (CanonGrabPan). A
 * touch that lands on a handle does not scroll the page; one anywhere else
 * does. `v-grab-pan="handlers"`.
 */
export const vGrabPan = elementDirective<GrabPanHandlers>(
  (element, handlers) => {
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
        handlers().grabs(local(touch.clientX, touch.clientY))
      )
        event.preventDefault();
    };
    const onDown = (event: PointerEvent) => {
      if (pointer !== undefined || event.button !== 0) return;
      if (!handlers().grabs(local(event.clientX, event.clientY))) return;
      pointer = event.pointerId;
      capture(element, event.pointerId);
      handlers().onBegin?.(event);
    };
    const onPointerMove = (event: PointerEvent) => {
      if (event.pointerId === pointer) handlers().onMove?.(event);
    };
    const onUp = (event: PointerEvent) => {
      if (event.pointerId !== pointer) return;
      pointer = undefined;
      handlers().onEnd?.(event);
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
