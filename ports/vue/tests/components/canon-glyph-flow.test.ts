import { reactive } from 'vue';
import { expect, test } from 'vitest';
import CanonGlyphFlow from '../../src/components/canon-glyph-flow.vue';
import type { GlyphKind } from '@canon/lib/glyph-rows.ts';
import {
  find,
  findAll,
  render,
  settled,
  waitUntil,
} from '../helpers/render.ts';

const metrics = { height: 36, rowGap: 8, gap: 4 };
const measure = () => 28;
const kind = (c: string): GlyphKind =>
  c === '\n' ? 'newline' : c === ' ' ? 'space' : 'glyph';

test('glyphs paint through the block, one row centred, wrapping when long', async () => {
  const state = reactive({ glyphs: [...'ab'] });
  await render(
    `<div style="width: 300px; height: 120px">
      <CanonGlyphFlow
        :glyphs="state.glyphs"
        :metrics="metrics"
        :measure="measure"
        :kind="kind"
        label="ab"
        v-slot="{ glyph, index }"
      ><span class="g" :data-index="index">{{ glyph }}</span></CanonGlyphFlow>
    </div>`,
    { CanonGlyphFlow, state, metrics, measure, kind },
  );
  await waitUntil(() => findAll('.g').length === 2);
  expect(find('.canon-glyph-flow')).toHaveAttribute('aria-label', 'ab');
  const boxes = findAll('.canon-glyph-flow-glyph');
  const left = parseFloat(boxes[0]!.style.left);
  const right = parseFloat(boxes[1]!.style.left) + 28;
  expect(left + right, 'a single row is centred').toBe(300);

  state.glyphs = [...'abcdefghijklmnopqrstuvwxyz'];
  await settled();
  const tops = new Set(
    findAll('.canon-glyph-flow-glyph').map((g) => g.style.top),
  );
  expect(tops.size > 1, 'wraps into rows').toBe(true);
});

test('no glyphs shows the empty block', async () => {
  const none: string[] = [];
  await render(
    `<div style="width: 300px; height: 120px">
      <CanonGlyphFlow :glyphs="none" :metrics="metrics" :measure="measure" :kind="kind">
        <template #empty><span class="nothing">Empty</span></template>
      </CanonGlyphFlow>
    </div>`,
    { CanonGlyphFlow, none, metrics, measure, kind },
  );
  expect(document.querySelector('.nothing')).not.toBeNull();
});

test('a change animates unless animated is false', async () => {
  const state = reactive({ glyphs: [...'ab'] });
  await render(
    `<div style="width: 300px; height: 120px">
      <CanonGlyphFlow class="on" :glyphs="state.glyphs" :metrics="metrics" :measure="measure" :kind="kind"
        v-slot="{ glyph, index }"><span class="g" :data-index="index">{{ glyph }}</span></CanonGlyphFlow>
    </div>
    <div style="width: 300px; height: 120px">
      <CanonGlyphFlow class="off" :glyphs="state.glyphs" :metrics="metrics" :measure="measure" :kind="kind"
        :animated="false" v-slot="{ glyph, index }"><span class="g" :data-index="index">{{ glyph }}</span></CanonGlyphFlow>
    </div>`,
    { CanonGlyphFlow, state, metrics, measure, kind },
  );
  await waitUntil(() => findAll('.g').length === 4);
  state.glyphs = [...'abc'];
  await settled();
  const glyph = (flow: string) =>
    find(`.${flow} [data-index="2"]`).parentElement!;
  expect(glyph('on').getAnimations().length).toBeGreaterThan(0);
  expect(glyph('off').getAnimations()).toHaveLength(0);
});
