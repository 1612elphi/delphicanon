<script lang="ts">
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLAttributes } from 'svelte/elements';
  import { capture } from '@canon/lib/motion.ts';
  import { clamp, dragSpeed, snap } from '@canon/lib/number.ts';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-slider.css';

  interface Props extends Omit<HTMLAttributes<HTMLDivElement>, 'children'> {
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
  }

  let {
    value: given,
    min = 0,
    max = 1,
    step,
    readout: format,
    fillsFromTrailing,
    labelledBy,
    label,
    onChange,
    class: className,
    onkeydown,
    ...rest
  }: Props = $props();

  const percent = (value: number) => `${Math.round(value * 100)}%`;

  let held = $state<{ value: number; over: number }>();
  let dragging = false;

  const span = $derived(max - min);
  const value = $derived(
    clamp(held && held.over === given ? held.value : given, min, max),
  );
  const readout = $derived((format ?? percent)(value));
  const fraction = $derived(span > 0 ? (value - min) / span : 0);

  function apply(raw: number) {
    const next = snap(raw, min, max, step);
    if (next === value) return;
    held = { value: next, over: given };
    onChange?.(next, dragging);
  }

  function key(event: KeyboardEvent & { currentTarget: HTMLDivElement }) {
    onkeydown?.(event);
    const by = step ?? span / 20;
    const next = {
      ArrowRight: value + by,
      ArrowUp: value + by,
      ArrowLeft: value - by,
      ArrowDown: value - by,
      Home: min,
      End: max,
    }[event.key];
    if (next === undefined) return;
    event.preventDefault();
    apply(next);
  }

  const drag: Attachment<HTMLDivElement> = (slider) => {
    const track = slider.querySelector<HTMLElement>('.canon-slider-track')!;
    let pointer: number | undefined;
    let start = { x: 0, y: 0 };
    let lastX = 0;
    let dragged = 0;

    const backwards = () =>
      (getComputedStyle(slider).direction === 'rtl') !==
      (fillsFromTrailing ?? false);
    const position = (x: number) => {
      const box = track.getBoundingClientRect();
      if (box.width <= 0) return undefined;
      const unit = clamp((x - box.left) / box.width, 0, 1);
      return min + (backwards() ? 1 - unit : unit) * span;
    };

    const down = (event: PointerEvent) => {
      if (event.button !== 0) return;
      pointer = event.pointerId;
      start = { x: event.clientX, y: event.clientY };
      dragging = false;
      capture(slider, pointer);
      slider.dataset['active'] = '';
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
      const box = slider.getBoundingClientRect();
      const speed = dragSpeed(
        Math.abs(event.clientY - (box.top + box.height / 2)),
      );
      const width = Math.max(1, track.getBoundingClientRect().width);
      const delta = ((event.clientX - lastX) / width) * span * speed;
      lastX = event.clientX;
      dragged = clamp(dragged + (backwards() ? -delta : delta), min, max);
      apply(dragged);
    };
    const end = (event: PointerEvent) => {
      if (event.pointerId !== pointer) return;
      if (event.type === 'pointerup' && !dragging) {
        const box = track.getBoundingClientRect();
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
      delete slider.dataset['active'];
    };

    slider.addEventListener('pointerdown', down);
    slider.addEventListener('pointermove', move);
    slider.addEventListener('pointerup', end);
    slider.addEventListener('pointercancel', end);
    return () => {
      slider.removeEventListener('pointerdown', down);
      slider.removeEventListener('pointermove', move);
      slider.removeEventListener('pointerup', end);
      slider.removeEventListener('pointercancel', end);
    };
  };
</script>

<!--
  @component
  Square slider with a readout cell. A tap sets the value; a sideways drag
  moves it, finer the further the pointer is pulled from the track.
-->
<div
  class={[
    'canon-slider',
    fillsFromTrailing && 'canon-slider--trailing',
    className,
  ]}
  role="slider"
  tabindex="0"
  aria-labelledby={labelledBy}
  aria-label={label}
  aria-valuemin={min}
  aria-valuemax={max}
  aria-valuenow={value}
  aria-valuetext={readout}
  style="--canon-slider-fraction: {fraction}"
  onkeydown={key}
  {@attach drag}
  {...rest}
>
  <div class="canon-slider-track">
    <div class="canon-slider-fill"></div>
    <div class="canon-slider-marker"></div>
  </div>
  <div class="canon-slider-readout" aria-hidden="true">{readout}</div>
</div>
