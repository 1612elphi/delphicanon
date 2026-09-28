<script lang="ts">
import type { GlyphKind } from '@canon/lib/glyph-rows.ts';

export const pane = 'main';
export const order = 30;

const start = 'Glyph flow';
const metrics = { height: 36, rowGap: 8, gap: 4 };
const measure = () => 28;
const kind = (c: string): GlyphKind =>
  c === '\n' ? 'newline' : /\s/.test(c) ? 'space' : 'glyph';
const isSpace = (c: string) => /\s/.test(c);
</script>

<script setup lang="ts">
import { computed, ref } from 'vue';
import CanonCanvas from '../../../src/components/canon-canvas.vue';
import CanonGlyphFlow from '../../../src/components/canon-glyph-flow.vue';
import CanonHeading from '../../../src/components/canon-heading.vue';
import CanonRows from '../../../src/components/canon-rows.vue';
import CanonTextInput from '../../../src/components/canon-text-input.vue';
import CanonTextOutput from '../../../src/components/canon-text-output.vue';
import '../../../../../demo-app/components/gallery/display.css';

const text = ref(start);
const glyphs = computed(() => [...text.value]);
const upper = computed(() => text.value.toUpperCase());
const change = (value: string) => {
  text.value = value;
};
</script>

<template>
  <CanonCanvas :height="120">
    <CanonGlyphFlow
      v-slot="{ glyph }"
      :glyphs="glyphs"
      :metrics="metrics"
      :measure="measure"
      :kind="kind"
      :label="text"
    >
      <span v-if="!isSpace(glyph)" class="gallery-glyph">{{ glyph }}</span>
    </CanonGlyphFlow>
  </CanonCanvas>
  <CanonRows :framed="true">
    <CanonHeading text="Text input" />
    <CanonTextInput :value="start" :on-change="change" />
  </CanonRows>
  <CanonTextOutput
    :text="upper"
    heading="Text output"
    file-name="gallery.txt"
  />
</template>
