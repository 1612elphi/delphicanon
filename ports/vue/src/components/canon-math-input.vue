<script lang="ts">
import { keypadHeight } from '@canon/lib/math/keypad.ts';
import { railHeights } from './canon-math-rail.vue';

/** Editor height, and the height in a short window. */
export const editorHeights = { regular: 112, short: 84 };
/** Windows shorter than this get the short keys and editor. */
export const shortWindow = 800;
/** Widest the docked sheet gets. */
export const maxWidth = 560;
/** Gap between the display and the keypad. */
export const gap = 12;
/** Container width from which the sheet docks to the pane: CanonSplit's two-column width. */
export const regularWidth = 640;
/** Drag, in px, or speed, in px per second, that closes the sheet. */
export const closing = { distance: 100, speed: 900 };

/** Height of the content, without the bottom safe area. */
export function contentHeight(short: boolean): number {
  const display =
    (short ? editorHeights.short : editorHeights.regular) +
    1 +
    (short ? railHeights.short : railHeights.regular);
  return 16 * 2 + 2 * 4 + display + gap + keypadHeight(short);
}

function still(): boolean {
  return matchMedia('(prefers-reduced-motion: reduce)').matches;
}
</script>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, useTemplateRef } from 'vue';
import { capture } from '@canon/lib/math/draw.ts';
import { Expression, type Key } from '@canon/lib/math/expression.ts';
import { keyForKeyboard } from '@canon/lib/math/keypad.ts';
import { springEasing } from '@canon/lib/motion.ts';
import { MathEditing } from '../lib/math-editing.ts';
import CanonMathEditor from './canon-math-editor.vue';
import CanonMathKeypad from './canon-math-keypad.vue';
import CanonMathRail from './canon-math-rail.vue';
import CanonRows from './canon-rows.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-input.css';

const props = defineProps<{
  /** nerdamer syntax. */
  text?: string;
  variable?: string;
  /** Typed once the sheet opens. */
  keys?: Key[];
  /** The element whose pane the sheet docks to on a regular width. */
  source?: HTMLElement;
  /** Every edit, with the text. */
  onChange?: (text: string) => void;
  /** The sheet closed, with the text. */
  onClose?: (text: string) => void;
}>();

const large = ref(false);
const pane = ref<{ left: number; width: number }>();
const short = window.innerHeight < shortWindow;
let finished = false;

const expression = new Expression(props.text ?? '', props.variable ?? 'x');
for (const key of props.keys ?? []) expression.apply(key);
const editing = new MathEditing(expression, (text) => props.onChange?.(text));
// the owner updates its own state, so not while it renders
if (props.keys?.length) queueMicrotask(() => props.onChange?.(expression.text));
const docked =
  (props.source?.closest('.canon-split') ?? document.documentElement)
    .clientWidth >= regularWidth;

const style = computed(() => {
  const box = pane.value;
  return (
    `--canon-math-sheet-height: ${contentHeight(short)}px; --canon-math-editor-height: ${short ? editorHeights.short : editorHeights.regular}px` +
    (box
      ? `; --canon-math-sheet-left: ${box.left}px; --canon-math-sheet-width: ${box.width}px`
      : '')
  );
});

/** The source's pane, the nearest CanonPage, or the whole window. */
function measurePane() {
  const page = props.source?.closest('.canon-page');
  const rect = page?.getBoundingClientRect();
  const box =
    rect && rect.width > 0
      ? rect
      : { left: 0, width: document.documentElement.clientWidth };
  const width = Math.min(maxWidth, box.width);
  pane.value = { left: box.left + (box.width - width) / 2, width };
}

const step = (key: Key) => editing.apply(key);
const type = (key: Key) => void editing.apply(key);

const dialog = useTemplateRef<HTMLDialogElement>('dialog');

function finish() {
  if (finished) return;
  finished = true;
  const element = dialog.value;
  const done = () => {
    element?.close();
    props.onClose?.(editing.expression.text);
  };
  if (!element || still()) return done();
  element
    .animate([{ transform: 'none' }, { transform: 'translateY(100%)' }], {
      duration: 250,
      easing: 'cubic-bezier(0.4, 0, 1, 1)',
      fill: 'forwards',
    })
    .finished.then(done, done);
}

let stop: (() => void) | undefined;

onMounted(() => {
  const element = dialog.value!;
  if (docked) measurePane();
  if (!element.open) element.showModal();
  element.focus({ preventScroll: true });
  if (!still())
    element.animate(
      [{ transform: 'translateY(100%)' }, { transform: 'none' }],
      {
        duration: 350,
        easing: 'cubic-bezier(0.2, 0.8, 0.2, 1)',
      },
    );

  const cancel = (event: Event) => {
    event.preventDefault();
    finish();
  };
  const outside = (event: MouseEvent) => {
    if (event.target !== element) return;
    const r = element.getBoundingClientRect();
    const inside =
      event.clientX >= r.left &&
      event.clientX <= r.right &&
      event.clientY >= r.top &&
      event.clientY <= r.bottom;
    if (!inside) finish();
  };
  const keydown = (event: KeyboardEvent) => {
    if (event.ctrlKey || event.metaKey || event.altKey) return;
    if (event.key === 'Enter') {
      event.preventDefault();
      finish();
      return;
    }
    const key = keyForKeyboard(event.key);
    if (!key) return;
    event.preventDefault();
    editing.apply(key);
  };

  // mostly-vertical drags only
  let start: { x: number; y: number } | undefined;
  let dragging = false;
  let travel = 0;
  let last = { y: 0, t: 0 };
  let speed = 0;
  const down = (event: PointerEvent) => {
    if (event.button !== 0 || !event.isPrimary) return;
    start = { x: event.clientX, y: event.clientY };
    dragging = false;
    travel = 0;
    speed = 0;
    last = { y: event.clientY, t: event.timeStamp };
  };
  const move = (event: PointerEvent) => {
    if (!start) return;
    const dx = event.clientX - start.x;
    const dy = event.clientY - start.y;
    if (!dragging) {
      if (Math.abs(dy) <= 10 || Math.abs(dy) <= Math.abs(dx)) return;
      dragging = true;
      capture(element, event.pointerId);
    }
    const dt = event.timeStamp - last.t;
    if (dt > 0) speed = ((event.clientY - last.y) / dt) * 1000;
    last = { y: event.clientY, t: event.timeStamp };
    travel = dy;
    // resists upwards unless it can grow
    const grows = !docked && !large.value;
    const shown = dy > 0 ? dy : grows ? Math.max(dy, -200) : dy / 6;
    element.style.translate = `0 ${shown}px`;
  };
  const up = () => {
    if (!start) return;
    start = undefined;
    if (!dragging) return;
    dragging = false;
    const down = travel > closing.distance || speed > closing.speed;
    const rise = travel < -60 || speed < -closing.speed;
    if (docked || !large.value) {
      if (down) return finish();
      if (rise && !docked) large.value = true;
    } else if (down) {
      if (travel > 400) return finish();
      large.value = false;
    }
    const from = element.style.translate;
    element.style.translate = '';
    if (!still())
      element.animate([{ translate: from }, { translate: '0 0' }], {
        duration: 350,
        easing: springEasing(0.8),
      });
  };

  element.addEventListener('cancel', cancel);
  element.addEventListener('click', outside);
  element.addEventListener('keydown', keydown);
  element.addEventListener('pointerdown', down);
  element.addEventListener('pointermove', move);
  element.addEventListener('pointerup', up);
  element.addEventListener('pointercancel', up);
  window.addEventListener('resize', measurePane);
  stop = () => {
    element.removeEventListener('cancel', cancel);
    element.removeEventListener('click', outside);
    element.removeEventListener('keydown', keydown);
    element.removeEventListener('pointerdown', down);
    element.removeEventListener('pointermove', move);
    element.removeEventListener('pointerup', up);
    element.removeEventListener('pointercancel', up);
    window.removeEventListener('resize', measurePane);
    if (element.open) element.close();
  };
});
onBeforeUnmount(() => stop?.());
</script>

<!--
  The expression over its caret rail and the keypad, as a sheet
  (CanonMathInputViewController with CanonPaneSheetPresentation). On a
  compact container a bottom sheet with a small and a large height; on a
  regular one docked to the bottom of the source's pane. Done, Enter,
  Escape, a drag down or a click outside closes it.
-->
<template>
  <dialog
    ref="dialog"
    class="canon-math-input"
    :class="[
      docked ? 'canon-math-input--docked' : 'canon-math-input--sheet',
      { 'canon-math-input--large': large },
    ]"
    aria-label="Expression"
    tabindex="-1"
    :style="style"
  >
    <span class="canon-math-input-grabber"></span>
    <div class="canon-math-input-stack">
      <CanonRows :framed="true" class="canon-math-input-display">
        <CanonMathEditor :editing="editing" :size="short ? 26 : 30" />
        <CanonMathRail :on-step="step" :short="short" />
      </CanonRows>
      <CanonRows :framed="true">
        <CanonMathKeypad
          :variable="variable"
          :short="short"
          :on-key="type"
          :on-done="finish"
        />
      </CanonRows>
    </div>
  </dialog>
</template>
