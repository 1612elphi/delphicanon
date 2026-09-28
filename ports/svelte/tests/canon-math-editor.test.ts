import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Editor from './fixtures/canon-math-editor-sized.svelte';
import { MathEditing } from '../src/lib/math-editing.svelte.ts';
import { Expression } from '@canon/lib/math/expression.ts';
import { find, settled, triggerEvent } from './helpers.ts';

describe('canon-math-editor', () => {
  test('the editor shows a caret and places it on a click', async () => {
    const editing = new MathEditing(new Expression('12+34'));
    await render(Editor, { editing });
    expect(find('.canon-math-editor-text').textContent).toBe('12+34');
    const caret = find('.canon-math-editor-caret');
    const end = caret.offsetLeft;
    const content = find('.canon-math-editor-content');
    const box = content.getBoundingClientRect();
    const scale = box.width / content.offsetWidth;
    await triggerEvent('.canon-math-editor', 'pointerdown', {
      button: 0,
      pointerId: 1,
      clientX: box.left + 17 * scale,
      clientY: box.top + box.height / 2,
    });
    await triggerEvent('.canon-math-editor', 'pointerup', { pointerId: 1 });
    expect(editing.expression.caret.index, 'caret at the start').toBe(0);
    expect(caret.offsetLeft).toBeLessThan(end);
    editing.apply({ kind: 'symbol', symbol: '9' });
    await settled();
    expect(find('.canon-math-editor-text').textContent).toBe('912+34');
  });
});
