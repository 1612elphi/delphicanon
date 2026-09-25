import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, rerender, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import CanonGlyphFlow from '#src/components/canon-glyph-flow.gts';
import type { GlyphKind } from '#src/lib/glyph-rows.ts';
import { css } from '../helpers/css.ts';

const metrics = { height: 36, rowGap: 8, gap: 4 };
const measure = () => 28;
const kind = (c: string): GlyphKind =>
  c === '\n' ? 'newline' : c === ' ' ? 'space' : 'glyph';

class State {
  @tracked glyphs = [...'ab'];
}

module('Component | canon-glyph-flow', function (hooks) {
  setupRenderingTest(hooks);

  test('glyphs paint through the block, one row centred, wrapping when long', async function (assert) {
    const state = new State();
    await render(
      <template>
        <div style={{css "width: 300px; height: 120px"}}>
          <CanonGlyphFlow
            @glyphs={{state.glyphs}}
            @metrics={{metrics}}
            @measure={{measure}}
            @kind={{kind}}
            @label="ab"
            as |glyph index|
          ><span
              class="g"
              data-index={{index}}
            >{{glyph}}</span></CanonGlyphFlow>
        </div>
      </template>,
    );
    await waitUntil(() => document.querySelectorAll('.g').length === 2);
    assert.dom('.canon-glyph-flow').hasAria('label', 'ab');
    const boxes = [
      ...document.querySelectorAll<HTMLElement>('.canon-glyph-flow-glyph'),
    ];
    const left = parseFloat(boxes[0]!.style.left);
    const right = parseFloat(boxes[1]!.style.left) + 28;
    assert.strictEqual(left + right, 300, 'a single row is centred');

    state.glyphs = [...'abcdefghijklmnopqrstuvwxyz'];
    await rerender();
    const tops = new Set(
      [
        ...document.querySelectorAll<HTMLElement>('.canon-glyph-flow-glyph'),
      ].map((g) => g.style.top),
    );
    assert.true(tops.size > 1, 'wraps into rows');
  });

  test('no glyphs shows the empty block', async function (assert) {
    const none: string[] = [];
    await render(
      <template>
        <div style={{css "width: 300px; height: 120px"}}>
          <CanonGlyphFlow
            @glyphs={{none}}
            @metrics={{metrics}}
            @measure={{measure}}
            @kind={{kind}}
          >
            <:empty><span class="nothing">Empty</span></:empty>
          </CanonGlyphFlow>
        </div>
      </template>,
    );
    assert.dom('.nothing').exists();
  });
});
