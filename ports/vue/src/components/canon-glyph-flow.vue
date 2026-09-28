<script lang="ts">
import type { Directive } from 'vue';
import type { Frame } from '@canon/lib/glyph-rows.ts';
import { curveEasing, glyphEased, glyphSettleMs } from '@canon/lib/motion.ts';

export interface GlyphMetrics {
  /** Height of a row of glyphs. */
  height: number;
  rowGap: number;
  /** Room between glyphs in a row; a space glyph adds its own width. */
  gap: number;
}

interface Motion {
  frame: Frame;
  from: Frame;
  appearing: boolean;
  moves: boolean;
}

const settleEasing = curveEasing(glyphEased);
const padding = 16;

function box(frame: Frame) {
  return `left: ${frame.x}px; top: ${frame.y}px; width: ${frame.width}px; height: ${frame.height}px`;
}

function intersects(a: Frame, b: Frame) {
  return (
    a.x < b.x + b.width &&
    b.x < a.x + a.width &&
    a.y < b.y + b.height &&
    b.y < a.y + a.height
  );
}

function still() {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

function glide(element: HTMLElement, placed: Motion) {
  element.getAnimations().forEach((animation) => animation.cancel());
  if (!placed.moves) return;
  if (placed.appearing) {
    element.animate([{ opacity: 0 }, { opacity: 1 }], {
      duration: glyphSettleMs * 0.4,
    });
    element.animate([{ transform: 'scale(0.55)' }, { transform: 'scale(1)' }], {
      duration: glyphSettleMs,
      easing: settleEasing,
    });
    return;
  }
  const dx = placed.from.x - placed.frame.x;
  const dy = placed.from.y - placed.frame.y;
  if (dx === 0 && dy === 0) return;
  element.animate(
    [{ transform: `translate(${dx}px, ${dy}px)` }, { transform: 'none' }],
    { duration: glyphSettleMs, easing: settleEasing },
  );
}

const vGlide: Directive<HTMLElement, Motion> = {
  mounted: (element, binding) => glide(element, binding.value),
  updated(element, binding) {
    if (binding.value !== binding.oldValue) glide(element, binding.value);
  },
};

const vFade: Directive<HTMLElement> = {
  mounted(element) {
    element.animate([{ opacity: 1 }, { opacity: 0 }], {
      duration: glyphSettleMs / 3,
      fill: 'forwards',
    });
  },
};
</script>

<script setup lang="ts" generic="G">
import { computed, onBeforeUnmount, onMounted, ref, useTemplateRef } from 'vue';
import { glyphRows, type GlyphKind } from '@canon/lib/glyph-rows.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-glyph-flow.css';

interface Placed extends Motion {
  glyph: G;
  index: number;
  style: string;
}

interface Previous {
  glyphs: G[];
  target: Frame[];
  start: Frame[];
  appearing: boolean[];
  began: number;
  width: number;
  height: number;
  metrics?: GlyphMetrics;
  focus?: number;
}

const props = withDefaults(
  defineProps<{
    glyphs: G[];
    metrics: GlyphMetrics;
    measure: (glyph: G) => number;
    kind: (glyph: G) => GlyphKind;
    /** Glyph kept in view with a row of context above it; none keeps the last row in view. */
    focus?: number;
    /** A change slides, grows and fades the glyphs; default true. */
    animated?: boolean;
    equals?: (a: G, b: G) => boolean;
    /** What the glyphs say, for assistive technology. */
    label?: string;
  }>(),
  { animated: undefined },
);

defineSlots<{
  /** Paints one glyph into its box; the index is null for a glyph fading out. */
  default?: (props: { glyph: G; index: number | null }) => unknown;
  /** The picture with no glyphs, in the content area. */
  empty?: () => unknown;
}>();

const width = ref(0);
const height = ref(0);
const root = useTemplateRef<HTMLElement>('root');
let previous: Previous = {
  glyphs: [],
  target: [],
  start: [],
  appearing: [],
  began: 0,
  width: 0,
  height: 0,
};
// ghosts get new elements on every scene, so each one fades from its own start
let generation = 0;
let stop: (() => void) | undefined;

onMounted(() => {
  const observer = new ResizeObserver(([entry]) => {
    if (!entry) return;
    const size = entry.contentRect;
    if (size.width !== width.value) width.value = size.width;
    if (size.height !== height.value) height.value = size.height;
  });
  observer.observe(root.value!);
  stop = () => observer.disconnect();
});
onBeforeUnmount(() => stop?.());

const area = computed<Frame>(() => ({
  x: padding,
  y: padding * 0.75,
  width: Math.max(0, width.value - padding * 2),
  height: Math.max(0, height.value - padding * 1.5),
}));

function layout(glyphs: G[]): { frames: Frame[]; window: Frame } {
  const { metrics, measure, kind, focus } = props;
  const room = area.value;
  if (room.width <= 0 || glyphs.length === 0)
    return {
      frames: glyphs.map(() => ({ x: 0, y: 0, width: 0, height: 0 })),
      window: room,
    };
  const pitch = metrics.height + metrics.rowGap;
  const { frames, rows } = glyphRows(
    glyphs.map(measure),
    glyphs.map(kind),
    room.width,
    metrics.gap,
    metrics.height,
    pitch,
  );
  const fit = Math.max(1, Math.floor((room.height + metrics.rowGap) / pitch));
  const focusFrame = focus === undefined ? undefined : frames[focus];
  const focusRow =
    focusFrame === undefined
      ? undefined
      : Math.round(focusFrame.y / pitch) - (fit > 2 ? 1 : 0);
  const first =
    rows <= fit ? 0 : Math.min(Math.max(0, focusRow ?? rows - fit), rows - fit);
  const block = Math.min(rows, fit) * pitch - metrics.rowGap;
  const y = room.y + Math.max(0, (room.height - block) / 2) - first * pitch;
  const widest = Math.max(0, ...frames.map((f) => f.x + f.width));
  const x = rows === 1 ? room.x + (room.width - widest) / 2 : room.x;
  return {
    frames: frames.map((f) => ({ ...f, x: f.x + x, y: f.y + y })),
    window: {
      x: 0,
      y: y + first * pitch - metrics.rowGap / 2,
      width: width.value,
      height: block + metrics.rowGap,
    },
  };
}

// the last scene is animation memory: frames to slide from, not rendered state
const scene = computed(() => {
  const { glyphs, metrics, focus } = props;
  const equals = props.equals ?? ((a: G, b: G) => a === b);
  const last = previous;
  const now = performance.now();
  const progress = Math.min(1, (now - last.began) / glyphSettleMs);
  const eased = glyphEased(progress);
  const shown = last.target.map((to, i) => {
    const from = last.start[i];
    if (progress >= 1 || !from || last.appearing[i]) return to;
    return {
      x: from.x + (to.x - from.x) * eased,
      y: from.y + (to.y - from.y) * eased,
      width: from.width + (to.width - from.width) * eased,
      height: from.height + (to.height - from.height) * eased,
    };
  });
  const { frames: target, window } = layout(glyphs);
  const moves =
    props.animated !== false && last.width > 0 && width.value > 0 && !still();

  const old = last.glyphs;
  const same =
    old.length === glyphs.length && old.every((g, i) => equals(g, glyphs[i]!));
  let start = target;
  let appearing = glyphs.map(() => false);
  let ghosts: { glyph: G; style: string }[] = [];
  let animating = false;

  if (!same && moves) {
    let prefix = 0;
    while (
      prefix < Math.min(old.length, glyphs.length) &&
      equals(old[prefix]!, glyphs[prefix]!)
    )
      prefix += 1;
    const limit = Math.min(old.length, glyphs.length) - prefix;
    let suffix = 0;
    while (
      suffix < limit &&
      equals(old[old.length - 1 - suffix]!, glyphs[glyphs.length - 1 - suffix]!)
    )
      suffix += 1;
    start = glyphs.map((_, i) => {
      if (i < prefix) return shown[i]!;
      if (i >= glyphs.length - suffix)
        return shown[i - glyphs.length + old.length]!;
      return target[i]!;
    });
    appearing = glyphs.map((_, i) => i >= prefix && i < glyphs.length - suffix);
    const bounds = { x: 0, y: 0, width: width.value, height: height.value };
    for (let i = prefix; i < old.length - suffix; i++) {
      const frame = shown[i];
      if (frame && frame.width > 0 && intersects(frame, bounds))
        ghosts.push({ glyph: old[i]!, style: box(frame) });
    }
    animating = true;
  } else if (same && moves) {
    const resettles =
      focus !== last.focus ||
      (progress < 1 &&
        (metrics !== last.metrics ||
          width.value !== last.width ||
          height.value !== last.height));
    if (resettles && shown.length === target.length) {
      start = shown;
      animating = true;
    }
  }
  if (!animating) ghosts = [];

  previous = {
    glyphs,
    target,
    start,
    appearing,
    began: animating ? now : last.began,
    width: width.value,
    height: height.value,
    metrics,
    focus,
  };
  generation += 1;

  const items: Placed[] = [];
  glyphs.forEach((glyph, index) => {
    const frame = target[index]!;
    if (frame.width <= 0) return;
    items.push({
      glyph,
      index,
      frame,
      from: start[index]!,
      appearing: appearing[index]!,
      moves: animating,
      style: box(frame),
    });
  });
  const bottom = height.value - (window.y + window.height);
  return {
    items,
    ghosts,
    generation,
    empty: glyphs.length === 0,
    clip: `clip-path: inset(${window.y}px 0 ${bottom}px 0)`,
    area: box(area.value),
  };
});
</script>

<!--
  A transliteration drawn as glyphs in wrapped rows, the last row in view:
  the banner of the text tools. On a change the glyphs that match at the
  start and the end slide to their new places, new ones grow in and removed
  ones fade.
-->
<template>
  <div ref="root" class="canon-glyph-flow" role="img" :aria-label="label">
    <div v-if="scene.empty" class="canon-glyph-flow-empty" :style="scene.area">
      <slot name="empty" />
    </div>
    <div class="canon-glyph-flow-glyphs" :style="scene.clip" aria-hidden="true">
      <div
        v-for="(ghost, i) in scene.ghosts"
        :key="`${scene.generation}-${i}`"
        v-fade
        class="canon-glyph-flow-glyph"
        :style="ghost.style"
      >
        <slot :glyph="ghost.glyph" :index="null" />
      </div>
      <div
        v-for="item in scene.items"
        :key="item.index"
        v-glide="item"
        class="canon-glyph-flow-glyph"
        :style="item.style"
      >
        <slot :glyph="item.glyph" :index="item.index" />
      </div>
    </div>
  </div>
</template>
