<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, useTemplateRef } from 'vue';
import { clamp, dragSpeed, snap } from '@canon/lib/number.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-slider.css';

const props = defineProps<{
  value: number;
  /** Default 0. A new range clamps the value without calling onChange. */
  min?: number;
  /** Default 1. */
  max?: number;
  /** Snaps the value to multiples of this above `min`. */
  step?: number;
  /** Text of the readout cell; default a percentage of 0 to 1. */
  readout?: (value: number) => string;
  /** Fills from the trailing edge towards the leading one: for amounts that count back from an end. */
  fillsFromTrailing?: boolean;
  labelledBy?: string;
  label?: string;
  /** `dragging` is true for a sideways drag, false for a tap or a key. */
  onChange?: (value: number, dragging: boolean) => void;
}>();

const percent = (value: number) => `${Math.round(value * 100)}%`;

const held = ref<{ value: number; over: number }>();
let dragging = false;

const min = computed(() => props.min ?? 0);
const max = computed(() => props.max ?? 1);
const span = computed(() => max.value - min.value);
const value = computed(() => {
  const raw =
    held.value && held.value.over === props.value
      ? held.value.value
      : props.value;
  return clamp(raw, min.value, max.value);
});
const readout = computed(() => (props.readout ?? percent)(value.value));
const style = computed(() => ({
  '--canon-slider-fraction': String(
    span.value > 0 ? (value.value - min.value) / span.value : 0,
  ),
}));

function apply(raw: number) {
  const next = snap(raw, min.value, max.value, props.step);
  if (next === value.value) return;
  held.value = { value: next, over: props.value };
  props.onChange?.(next, dragging);
}

function key(event: KeyboardEvent) {
  const step = props.step ?? span.value / 20;
  const next = {
    ArrowRight: value.value + step,
    ArrowUp: value.value + step,
    ArrowLeft: value.value - step,
    ArrowDown: value.value - step,
    Home: min.value,
    End: max.value,
  }[event.key];
  if (next === undefined) return;
  event.preventDefault();
  apply(next);
}

const slider = useTemplateRef<HTMLElement>('slider');
const track = useTemplateRef<HTMLElement>('track');
let stop: (() => void) | undefined;

onMounted(() => {
  const element = slider.value!;
  const bar = track.value!;
  let pointer: number | undefined;
  let start = { x: 0, y: 0 };
  let lastX = 0;
  let dragged = 0;

  const backwards = () =>
    (getComputedStyle(element).direction === 'rtl') !==
    (props.fillsFromTrailing ?? false);
  const position = (x: number) => {
    const box = bar.getBoundingClientRect();
    if (box.width <= 0) return undefined;
    const unit = clamp((x - box.left) / box.width, 0, 1);
    return min.value + (backwards() ? 1 - unit : unit) * span.value;
  };

  const down = (event: PointerEvent) => {
    if (event.button !== 0) return;
    pointer = event.pointerId;
    start = { x: event.clientX, y: event.clientY };
    dragging = false;
    element.setPointerCapture?.(pointer);
    element.dataset['active'] = '';
  };
  const move = (event: PointerEvent) => {
    if (event.pointerId !== pointer) return;
    if (!dragging) {
      const dx = Math.abs(event.clientX - start.x);
      const at = position(event.clientX);
      if (
        dx <= 4 ||
        dx <= Math.abs(event.clientY - start.y) ||
        at === undefined
      )
        return;
      // absolute first, then relative
      dragging = true;
      dragged = at;
      lastX = event.clientX;
      apply(dragged);
      return;
    }
    const box = element.getBoundingClientRect();
    const speed = dragSpeed(
      Math.abs(event.clientY - (box.top + box.height / 2)),
    );
    const width = Math.max(1, bar.getBoundingClientRect().width);
    const delta = ((event.clientX - lastX) / width) * span.value * speed;
    lastX = event.clientX;
    dragged = clamp(
      dragged + (backwards() ? -delta : delta),
      min.value,
      max.value,
    );
    apply(dragged);
  };
  const end = (event: PointerEvent) => {
    if (event.pointerId !== pointer) return;
    if (event.type === 'pointerup' && !dragging) {
      const box = bar.getBoundingClientRect();
      const inside =
        event.clientX >= box.left &&
        event.clientX <= box.right &&
        event.clientY >= box.top &&
        event.clientY <= box.bottom;
      const at = position(event.clientX);
      if (inside && at !== undefined) apply(at);
    }
    pointer = undefined;
    dragging = false;
    delete element.dataset['active'];
  };

  element.addEventListener('pointerdown', down);
  element.addEventListener('pointermove', move);
  element.addEventListener('pointerup', end);
  element.addEventListener('pointercancel', end);
  stop = () => {
    element.removeEventListener('pointerdown', down);
    element.removeEventListener('pointermove', move);
    element.removeEventListener('pointerup', end);
    element.removeEventListener('pointercancel', end);
  };
});
onBeforeUnmount(() => stop?.());
</script>

<!--
  Square slider with a readout cell. A tap sets the value; a sideways drag
  moves it, finer the further the pointer is pulled from the track.
-->
<template>
  <div
    ref="slider"
    class="canon-slider"
    :class="{ 'canon-slider--trailing': fillsFromTrailing }"
    role="slider"
    tabindex="0"
    :aria-labelledby="labelledBy"
    :aria-label="label"
    :aria-valuemin="min"
    :aria-valuemax="max"
    :aria-valuenow="value"
    :aria-valuetext="readout"
    :style="style"
    @keydown="key"
  >
    <div ref="track" class="canon-slider-track">
      <div class="canon-slider-fill"></div>
      <div class="canon-slider-marker"></div>
    </div>
    <div class="canon-slider-readout" aria-hidden="true">{{ readout }}</div>
  </div>
</template>
