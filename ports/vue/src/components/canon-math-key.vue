<script lang="ts">
/** Travel in px that turns a press into a drag. */
export const slop = 10;
</script>

<script setup lang="ts">
import { computed, onBeforeUnmount } from 'vue';
import { vPress } from '../lib/press.ts';
import { chevronUp } from '../lib/lucide.ts';
import { repeatTiming } from './canon-button.vue';
import CanonIcon from './canon-icon.vue';
import CanonMathView from './canon-math-view.vue';
import type { Key } from '@canon/lib/math/expression.ts';
import {
  familyOf,
  keyHeights,
  label as labelFor,
  labelShare,
  spoken,
  type Family,
} from '@canon/lib/math/keypad.ts';
import { canvasMetrics } from '@canon/lib/math/measure.ts';
import type { Box } from '@canon/lib/math/typeset.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-key.css';

const props = defineProps<{
  /** The key typed; gives the label, the family and the spoken name. Ember's `@key`; `key` is reserved in Vue. */
  mathKey?: Key;
  /** The letter the derivative key shows; default x. */
  variable?: string;
  /** Label size in px before `scale`; default 24, the regular key's. */
  size?: number;
  scale?: number;
  /** A label set elsewhere, instead of the key's. */
  face?: Box;
  family?: Family;
  /** Accessible name; default the key's spoken name. */
  label?: string;
  /** Marks a key that opens a submenu with a chevron. */
  menu?: boolean;
  /** Holding repeats the tap, as delete does. */
  repeats?: boolean;
  onClick?: () => void;
}>();

defineSlots<{ default?: () => unknown }>();

let start: { x: number; y: number } | undefined;
let moved = false;
let held = false;
let didRepeat = false;
let timer: number | undefined;

const family = computed(
  (): Family =>
    props.family ?? (props.mathKey ? familyOf(props.mathKey) : 'digit'),
);

const face = computed((): Box | undefined => {
  if (props.face) return props.face;
  if (!props.mathKey) return undefined;
  const size = props.size ?? Math.round(keyHeights.regular * labelShare);
  return labelFor(
    props.mathKey,
    props.variable ?? 'x',
    size * (props.scale ?? 1),
    canvasMetrics,
  );
});

const label = computed(
  () =>
    props.label ??
    (props.mathKey ? spoken(props.mathKey, props.variable ?? 'x') : undefined),
);

function click() {
  if (moved || didRepeat) {
    didRepeat = false;
    return;
  }
  props.onClick?.();
}

function down(event: PointerEvent) {
  start = { x: event.clientX, y: event.clientY };
  moved = false;
  didRepeat = false;
  if (!props.repeats || event.button !== 0) return;
  held = true;
  schedule(repeatTiming.delay, 0);
}

function move(event: PointerEvent) {
  if (!start || moved) return;
  const travel = Math.hypot(event.clientX - start.x, event.clientY - start.y);
  if (travel > slop && !didRepeat) {
    moved = true;
    letGo();
  }
}

function letGo() {
  held = false;
  window.clearTimeout(timer);
}

function schedule(seconds: number, count: number) {
  window.clearTimeout(timer);
  timer = window.setTimeout(() => {
    if (!held) return;
    didRepeat = true;
    props.onClick?.();
    schedule(count < 10 ? repeatTiming.interval : repeatTiming.fast, count + 1);
  }, seconds * 1000);
}

onBeforeUnmount(letGo);
</script>

<!--
  One key: a flush cell in its family's colours with one label, set large
  and centred (CanonMathKeyView). A tap does one thing; a drag past the slop
  does nothing. Outside the keypad it is the insert cell
  (`CanonMathKeypad.cell`).
-->
<template>
  <button
    v-press
    type="button"
    class="canon-math-key"
    :class="`canon-math-key--${family}`"
    :aria-label="label"
    :aria-haspopup="menu ? 'true' : undefined"
    @pointerdown="down"
    @pointermove="move"
    @pointerup="letGo"
    @pointercancel="letGo"
    @lostpointercapture="letGo"
    @click="click"
  >
    <span class="canon-math-key-face">
      <slot v-if="$slots.default" />
      <CanonMathView
        v-else-if="face"
        :box="face"
        :mono="true"
        aria-hidden="true"
      />
      <span v-if="menu" class="canon-math-key-chevron"
        ><CanonIcon :svg="chevronUp"
      /></span>
    </span>
  </button>
</template>
