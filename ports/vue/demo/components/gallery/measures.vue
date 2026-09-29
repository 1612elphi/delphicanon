<script lang="ts">
export const pane = 'main';
export const order = 16;
</script>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, useTemplateRef } from 'vue';
import CanonCanvas from '../../../src/components/canon-canvas.vue';
import CanonCompressionScale from '../../../src/components/canon-compression-scale.vue';
import CanonDimensionLine from '../../../src/components/canon-dimension-line.vue';
import CanonHeading from '../../../src/components/canon-heading.vue';
import CanonRow from '../../../src/components/canon-row.vue';
import CanonRows from '../../../src/components/canon-rows.vue';
import CanonSegmented from '../../../src/components/canon-segmented.vue';
import CanonSwitch from '../../../src/components/canon-switch.vue';
import { dimensionLines, sheet, type Rect } from '@canon/lib/dimension-line.ts';
import '../../../../../demo-app/components/gallery/measures.css';

const picture = { width: 1600, height: 1200 };

const scales = [
  { title: 'Saved', before: 2_400_000, after: 1_700_000, working: false },
  { title: 'Grew', before: 2_400_000, after: 3_100_000, working: false },
  { title: 'Even', before: 2_400_000, after: 2_400_000, working: false },
  { title: 'Working', before: 2_400_000, after: 0, working: true },
  { title: 'Empty', before: 0, after: 0, working: false },
];
const titles = scales.map((scale) => scale.title);

const box = ({ x, y, width, height }: Rect) => ({
  insetInlineStart: `${x}px`,
  insetBlockStart: `${y}px`,
  inlineSize: `${width}px`,
  blockSize: `${height}px`,
});

const area = ref<Rect>({ x: 0, y: 0, width: 0, height: 0 });
const scale = ref(0);
const blank = ref(false);
const frame = computed(() => sheet(picture, area.value));
const lines = computed(() => {
  const { across, down } = dimensionLines(frame.value);
  return { sheet: box(frame.value), across: box(across), down: box(down) };
});
const shown = computed(() => scales[scale.value]!);

const measured = useTemplateRef<HTMLElement>('measured');
let observer: ResizeObserver | undefined;
onMounted(() => {
  const element = measured.value!;
  observer = new ResizeObserver(() => {
    area.value = {
      x: element.offsetLeft,
      y: element.offsetTop,
      width: element.clientWidth,
      height: element.clientHeight,
    };
  });
  observer.observe(element);
});
onBeforeUnmount(() => observer?.disconnect());
</script>

<template>
  <CanonCanvas :height="220" background="var(--canon-muted)">
    <div class="gallery-dimensions">
      <span ref="measured" class="gallery-dimensions-area" />
      <template v-if="area.width">
        <span class="gallery-dimensions-sheet" :style="lines.sheet" />
        <CanonDimensionLine
          :pixels="picture.width"
          :blank="blank"
          :style="lines.across"
        />
        <CanonDimensionLine
          :pixels="picture.height"
          :blank="blank"
          down
          :style="lines.down"
        />
      </template>
    </div>
  </CanonCanvas>
  <CanonCanvas :height="176">
    <CanonCompressionScale
      :before="shown.before"
      :after="shown.after"
      format="JPEG"
      :working="shown.working"
    />
  </CanonCanvas>
  <CanonRows framed>
    <CanonHeading text="Measures" />
    <CanonSegmented
      :items="titles"
      :selected="scale"
      :on-change="(index: number) => (scale = index)"
    />
    <CanonRow v-slot="{ titleId }" title="Blank">
      <CanonSwitch
        :on="blank"
        :on-change="(on: boolean) => (blank = on)"
        :aria-labelledby="titleId"
      />
    </CanonRow>
  </CanonRows>
</template>
