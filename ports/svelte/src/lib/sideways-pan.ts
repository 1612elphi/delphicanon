import type { Attachment } from 'svelte/attachments';
import { sidewaysJudgement } from '@canon/lib/motion.ts';

export interface PanHandlers {
  onBegin?: (event: PointerEvent) => void;
  onMove?: (event: PointerEvent) => void;
  onEnd?: (event: PointerEvent) => void;
}

/**
 * A sideways drag inside a scrolling page (CanonSidewaysPan). The page keeps
 * vertical touch scrolling through `touch-action: pan-y`; a drag that is not
 * clearly sideways after a few px never begins.
 * `{@attach sidewaysPan({ onBegin, onMove, onEnd })}`.
 */
export function sidewaysPan({
  onBegin,
  onMove,
  onEnd,
}: PanHandlers): Attachment<HTMLElement> {
  return (element) => {
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
        element.setPointerCapture?.(event.pointerId);
        onBegin?.(event);
      }
      onMove?.(event);
    };
    const onUp = (event: PointerEvent) => {
      if (event.pointerId !== pointer) return;
      pointer = undefined;
      if (began) onEnd?.(event);
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
  };
}
