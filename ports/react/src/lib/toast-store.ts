import { useSyncExternalStore } from 'react';
import { toastDetail, toastHold } from '@canon/lib/toast.ts';

export interface ToastState {
  detail?: string;
  visible: boolean;
  /** Counts shows, so the outlet can tell a repeat from a first show. */
  shown: number;
}

let state: ToastState = { visible: false, shown: 0 };
let timer: number | undefined;
const listeners = new Set<() => void>();

function set(next: Partial<ToastState>) {
  state = { ...state, ...next };
  listeners.forEach((listener) => listener());
}

/**
 * Drives the one CanonToast outlet: a short "Copied" note with the copied
 * value, near the bottom of the column the last pointer went down in.
 * `copy` is CanonCopyFeedback.copy: every tapped value copy confirms with
 * the toast and nothing else.
 */
export const canonToast = {
  lastPointer: undefined as
    { x: number; y: number; target: Element | null } | undefined,

  /** Shows the toast; the detail appears when it is one short line. */
  show(detail?: string) {
    window.clearTimeout(timer);
    set({ detail: toastDetail(detail), visible: true, shown: state.shown + 1 });
    timer = window.setTimeout(() => set({ visible: false }), toastHold * 1000);
  },

  /** Copies `text` and confirms with the toast. Nothing shows if the write fails. */
  async copy(text: string) {
    try {
      await canonToast.write(text);
    } catch {
      return;
    }
    canonToast.show(text);
  },

  /** The clipboard write; tests replace it. */
  write(text: string): Promise<void> {
    return navigator.clipboard.writeText(text);
  },
};

if (typeof document !== 'undefined') {
  document.addEventListener(
    'pointerdown',
    (event) => {
      canonToast.lastPointer = {
        x: event.clientX,
        y: event.clientY,
        target: event.target instanceof Element ? event.target : null,
      };
    },
    { capture: true, passive: true },
  );
}

function subscribe(listener: () => void) {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

/** The toast's state, for the outlet. */
export function useToastState(): ToastState {
  return useSyncExternalStore(subscribe, () => state);
}
