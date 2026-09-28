import { useSyncExternalStore } from 'react';
import type { Expression, Key, Row } from '@canon/lib/math/expression.ts';

/** An expression being edited, as a store shared by the editor, the keypad and the rail. */
export class MathEditing {
  /** Counts changes; `useMathEditing` re-renders on each. */
  version = 0;
  /** The next layout morphs: true after a key, false after the caret is placed by pointer. */
  animates = false;
  #listeners = new Set<() => void>();

  constructor(
    public expression: Expression,
    public onChange?: (text: string) => void,
  ) {}

  subscribe = (listener: () => void) => {
    this.#listeners.add(listener);
    return () => void this.#listeners.delete(listener);
  };

  #bump() {
    this.version += 1;
    this.#listeners.forEach((listener) => listener());
  }

  /** False when the key changed neither the text nor the caret. */
  apply = (key: Key): boolean => {
    const before = { text: this.expression.text, ...this.expression.caret };
    this.expression.apply(key);
    const { row, index } = this.expression.caret;
    const changed = this.expression.text !== before.text;
    if (!changed && row === before.row && index === before.index) return false;
    this.animates = true;
    this.#bump();
    if (changed) this.onChange?.(this.expression.text);
    return true;
  };

  moveCaret(row: Row, index: number): void {
    const caret = this.expression.caret;
    if (caret.row === row && caret.index === index) return;
    this.expression.caret = { row, index };
    this.animates = false;
    this.#bump();
  }
}

/** The editing's version, re-rendering the caller on every change. */
export function useMathEditing(editing: MathEditing): number {
  return useSyncExternalStore(editing.subscribe, () => editing.version);
}
