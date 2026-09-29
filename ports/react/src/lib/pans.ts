import { useCallback, type RefObject } from 'react';
import { capture, sidewaysJudgement } from '@canon/lib/motion.ts';
import { useLatest } from './refs.ts';

export interface PanHandlers {
  onBegin?: (event: PointerEvent) => void;
  onMove?: (event: PointerEvent) => void;
  onEnd?: (event: PointerEvent) => void;
}

export interface GrabPanHandlers extends PanHandlers {
  /** Whether a drag may begin at this point, in the element's own box. */
  grabs: (point: { x: number; y: number }) => boolean;
}

/** A stable ref callback that always calls the latest handlers. */
function usePan<H>(
  handlers: H,
  attach: (element: HTMLElement, latest: RefObject<H>) => () => void,
) {
  const latest = useLatest(handlers);
  return useCallback(
    (element: HTMLElement | null) =>
      element ? attach(element, latest) : undefined,
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  );
}

/**
 * A sideways drag inside a scrolling page (CanonSidewaysPan). The page keeps
 * vertical touch scrolling through `touch-action: pan-y`; a drag that is not
 * clearly sideways after a few px never begins. Returns a ref callback.
 */
export function useSidewaysPan(handlers: PanHandlers) {
  return usePan(handlers, (element, latest) => {
    let pointer: number | undefined;
    let origin = { x: 0, y: 0 };
    let began = false;

    const onDown = (event: PointerEvent) => {
      if (pointer !== undefined || event.button !== 0) return;
      pointer = event.pointerId;
      origin = { x: event.clientX, y: event.clientY };
      began = false;
    };
    const onPointerMove = (event: PointerEvent) => {
      if (event.pointerId !== pointer) return;
      if (!began) {
        const across = Math.abs(event.clientX - origin.x);
        const down = Math.abs(event.clientY - origin.y);
        if (Math.max(across, down) < sidewaysJudgement.travel) return;
        if (across < down * sidewaysJudgement.ratio) {
          pointer = undefined;
          return;
        }
        began = true;
        capture(element, event.pointerId);
        latest.current.onBegin?.(event);
      }
      latest.current.onMove?.(event);
    };
    const onUp = (event: PointerEvent) => {
      if (event.pointerId !== pointer) return;
      pointer = undefined;
      if (began) latest.current.onEnd?.(event);
    };

    const previous = element.style.touchAction;
    element.style.touchAction = 'pan-y';
    element.addEventListener('pointerdown', onDown);
    element.addEventListener('pointermove', onPointerMove);
    element.addEventListener('pointerup', onUp);
    element.addEventListener('pointercancel', onUp);
    return () => {
      element.style.touchAction = previous;
      element.removeEventListener('pointerdown', onDown);
      element.removeEventListener('pointermove', onPointerMove);
      element.removeEventListener('pointerup', onUp);
      element.removeEventListener('pointercancel', onUp);
    };
  });
}

/**
 * A drag in any direction that begins only on a handle (CanonGrabPan). A
 * touch that lands on a handle does not scroll the page; one anywhere else
 * does. Returns a ref callback.
 */
export function useGrabPan(handlers: GrabPanHandlers) {
  return usePan(handlers, (element, latest) => {
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
        latest.current.grabs(local(touch.clientX, touch.clientY))
      )
        event.preventDefault();
    };
    const onDown = (event: PointerEvent) => {
      if (pointer !== undefined || event.button !== 0) return;
      if (!latest.current.grabs(local(event.clientX, event.clientY))) return;
      pointer = event.pointerId;
      capture(element, event.pointerId);
      latest.current.onBegin?.(event);
    };
    const onPointerMove = (event: PointerEvent) => {
      if (event.pointerId === pointer) latest.current.onMove?.(event);
    };
    const onUp = (event: PointerEvent) => {
      if (event.pointerId !== pointer) return;
      pointer = undefined;
      latest.current.onEnd?.(event);
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
  });
}
