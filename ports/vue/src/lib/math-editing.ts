import { markRaw, shallowRef } from 'vue';
import type { Expression, Key, Row } from '@canon/lib/math/expression.ts';

/** An expression being edited, as reactive state shared by the editor, the keypad and the rail. */
export class MathEditing {
  readonly #version = shallowRef(0);
  /** The next layout morphs: true after a key, false after the caret is placed by pointer. */
  animates = false;

  constructor(
    public expression: Expression,
    public onChange?: (text: string) => void,
  ) {
    // private fields do not survive a reactive proxy
    markRaw(this);
  }

  get version(): number {
    return this.#version.value;
  }

  /** False when the key changed neither the text nor the caret. */
  apply = (key: Key): boolean => {
    const before = { text: this.expression.text, ...this.expression.caret };
    this.expression.apply(key);
    const { row, index } = this.expression.caret;
    const changed = this.expression.text !== before.text;
    if (!changed && row === before.row && index === before.index) return false;
    this.animates = true;
    this.#version.value += 1;
    if (changed) this.onChange?.(this.expression.text);
    return true;
  };

  moveCaret(row: Row, index: number): void {
    const caret = this.expression.caret;
    if (caret.row === row && caret.index === index) return;
    this.expression.caret = { row, index };
    this.animates = false;
    this.#version.value += 1;
  }
}
