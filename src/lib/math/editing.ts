import { tracked } from '@glimmer/tracking';
import type { Expression, Key, Row } from './expression.ts';

/** An expression being edited, as tracked state shared by the editor, the keypad and the rail. */
export class MathEditing {
  @tracked version = 0;
  /** The next layout morphs: true after a key, false after the caret is placed by pointer. */
  animates = false;

  constructor(
    public expression: Expression,
    public onChange?: (text: string) => void,
  ) {}

  /** False when the key changed neither the text nor the caret. */
  apply = (key: Key): boolean => {
    const before = { text: this.expression.text, ...this.expression.caret };
    this.expression.apply(key);
    const { row, index } = this.expression.caret;
    const changed = this.expression.text !== before.text;
    if (!changed && row === before.row && index === before.index) return false;
    this.animates = true;
    this.version += 1;
    if (changed) this.onChange?.(this.expression.text);
    return true;
  };

  moveCaret(row: Row, index: number): void {
    const caret = this.expression.caret;
    if (caret.row === row && caret.index === index) return;
    this.expression.caret = { row, index };
    this.animates = false;
    this.version += 1;
  }
}
