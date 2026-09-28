import { describe, expect, test } from 'vitest';
import CanonMathEditor from '../../src/components/canon-math-editor.tsx';
import { Expression } from '@canon/lib/math/expression.ts';
import { MathEditing } from '../../src/lib/math-editing.ts';
import { find, render, settle, trigger } from '../helpers/render.tsx';

describe('canon-math-editor', () => {
  test('the editor shows a caret and places it on a click', async () => {
    const editing = new MathEditing(new Expression('12+34'));
    await render(
      <div style={{ width: 300, height: 112, display: 'flex' }}>
        <CanonMathEditor editing={editing} />
      </div>,
    );
    expect(find('.canon-math-editor-text').textContent).toBe('12+34');
    const caret = find('.canon-math-editor-caret');
    const end = caret.offsetLeft;
    const content = find('.canon-math-editor-content');
    const box = content.getBoundingClientRect();
    const scale = box.width / content.offsetWidth;
    await trigger('.canon-math-editor', 'pointerdown', {
      button: 0,
      pointerId: 1,
      clientX: box.left + 17 * scale,
      clientY: box.top + box.height / 2,
    });
    await trigger('.canon-math-editor', 'pointerup', { pointerId: 1 });
    expect(editing.expression.caret.index).toBe(0);
    expect(caret.offsetLeft).toBeLessThan(end);
    await settle(() => editing.apply({ kind: 'symbol', symbol: '9' }));
    expect(find('.canon-math-editor-text').textContent).toBe('912+34');
  });
});
