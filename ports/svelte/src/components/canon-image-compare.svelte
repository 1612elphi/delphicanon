<script lang="ts">
  import type { HTMLAttributes } from 'svelte/elements';
  import { compareSpring, springEasing } from '@canon/lib/motion.ts';
  import { sidewaysPan } from '../lib/sideways-pan.ts';
  import { arrowLeftRight } from '../lib/control-icons.ts';
  import CanonIcon from './canon-icon.svelte';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-image-compare.css';

  interface Props extends HTMLAttributes<HTMLDivElement> {
    /** URL of the original. */
    before?: string;
    /** URL of the result. */
    after?: string;
    /** The result could not be made: the original dims and `failure` shows. */
    failed?: boolean;
    /** Shown over the original when `failed`. */
    failure?: string;
    beforeTitle?: string;
    afterTitle?: string;
  }

  let {
    before,
    after,
    failed,
    failure,
    beforeTitle = 'Before',
    afterTitle = 'After',
    class: className,
    onclick,
    onkeydown,
    ...rest
  }: Props = $props();

  const tapEasing = springEasing(compareSpring.damping);
  const nudge = 0.1;

  /** Share of the width that shows the original. */
  let split = $state(0.5);
  let springs = $state(false);
  let dragged = false;

  const comparing = $derived(Boolean(before && after));
  const percent = $derived(Math.round(split * 100));

  function move(element: HTMLElement, clientX: number, spring: boolean) {
    const box = element.getBoundingClientRect();
    if (box.width <= 0 || !comparing) return;
    let share = (clientX - box.left) / box.width;
    if (getComputedStyle(element).direction === 'rtl') share = 1 - share;
    springs =
      spring && !window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    split = Math.min(Math.max(share, 0), 1);
  }

  const onBegin = () => {
    dragged = true;
  };

  const onMove = (event: PointerEvent) => {
    move(event.currentTarget as HTMLElement, event.clientX, false);
  };

  function click(event: MouseEvent & { currentTarget: HTMLDivElement }) {
    onclick?.(event);
    if (dragged) {
      dragged = false;
      return;
    }
    move(event.currentTarget, event.clientX, true);
  }

  function key(event: KeyboardEvent & { currentTarget: HTMLDivElement }) {
    onkeydown?.(event);
    if (!comparing) return;
    const sign =
      getComputedStyle(event.currentTarget).direction === 'rtl' ? -1 : 1;
    const steps: Record<string, number> = {
      ArrowRight: nudge * sign,
      ArrowLeft: -nudge * sign,
      ArrowUp: nudge,
      ArrowDown: -nudge,
      Home: -1,
      End: 1,
    };
    const step = steps[event.key];
    if (step === undefined) return;
    event.preventDefault();
    springs = false;
    split = Math.min(Math.max(split + step, 0), 1);
  }
</script>

<!--
  @component
  One picture, the original on the leading side of a draggable divider and
  the result on the other; a tap moves the divider. To assistive technology
  it is a slider.
-->
<!-- svelte-ignore a11y_no_noninteractive_tabindex -->
<div
  class={[
    'canon-image-compare',
    comparing && 'canon-image-compare--comparing',
    failed && 'canon-image-compare--failed',
    className,
  ]}
  style:--canon-compare-split={split}
  style:--canon-compare-transition={springs
    ? `${compareSpring.ms}ms ${tapEasing}`
    : undefined}
  role={comparing ? 'slider' : undefined}
  tabindex={comparing ? 0 : undefined}
  aria-label="{beforeTitle}, {afterTitle}"
  aria-valuemin={comparing ? 0 : undefined}
  aria-valuemax={comparing ? 100 : undefined}
  aria-valuenow={comparing ? percent : undefined}
  aria-valuetext={comparing ? `${percent}%` : undefined}
  {@attach sidewaysPan({ onBegin, onMove })}
  onclick={click}
  onkeydown={key}
  {...rest}
>
  {#if before}
    <img
      class="canon-image-compare-before"
      src={before}
      alt=""
      draggable="false"
    />
  {/if}
  {#if comparing}
    <div class="canon-image-compare-after">
      <img src={after} alt="" draggable="false" />
    </div>
    <div class="canon-image-compare-divider"></div>
    <div class="canon-image-compare-grip">
      <CanonIcon svg={arrowLeftRight} />
    </div>
    <span class="canon-image-compare-tag canon-image-compare-tag--before"
      >{beforeTitle}</span
    >
    <span class="canon-image-compare-tag canon-image-compare-tag--after"
      >{afterTitle}</span
    >
  {/if}
  {#if failed}
    <p class="canon-image-compare-failure" role="status">{failure}</p>
  {/if}
</div>
