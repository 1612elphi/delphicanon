<script lang="ts" module>
  export interface GlyphMetrics {
    /** Height of a row of glyphs. */
    height: number;
    rowGap: number;
    /** Room between glyphs in a row; a space glyph adds its own width. */
    gap: number;
  }
</script>

<script lang="ts" generics="G">
  import type { Snippet } from 'svelte';
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLAttributes } from 'svelte/elements';
  import {
    glyphRows,
    type Frame,
    type GlyphKind,
  } from '@canon/lib/glyph-rows.ts';
  import { curveEasing, glyphEased, glyphSettleMs } from '@canon/lib/motion.ts';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-glyph-flow.css';

  interface Props extends Omit<HTMLAttributes<HTMLDivElement>, 'children'> {
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
    /** Paints one glyph into its box; the index is null for a glyph fading out. */
    children?: Snippet<[glyph: G, index: number | null]>;
    /** The picture with no glyphs, in the content area. */
    empty?: Snippet;
  }

  let {
    glyphs,
    metrics,
    measure,
    kind,
    focus,
    animated,
    equals = (a: G, b: G) => a === b,
    label,
    children,
    empty,
    class: className,
    ...rest
  }: Props = $props();

  interface Placed {
    glyph: G;
    index: number;
    frame: Frame;
    from: Frame;
    appearing: boolean;
    moves: boolean;
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

  function glide(
    placed: Pick<Placed, 'frame' | 'from' | 'appearing' | 'moves'>,
  ): Attachment<HTMLElement> {
    return (element) => {
      element.getAnimations().forEach((animation) => animation.cancel());
      if (!placed.moves) return;
      if (placed.appearing) {
        element.animate([{ opacity: 0 }, { opacity: 1 }], {
          duration: glyphSettleMs * 0.4,
        });
        element.animate(
          [{ transform: 'scale(0.55)' }, { transform: 'scale(1)' }],
          { duration: glyphSettleMs, easing: settleEasing },
        );
        return;
      }
      const dx = placed.from.x - placed.frame.x;
      const dy = placed.from.y - placed.frame.y;
      if (dx === 0 && dy === 0) return;
      element.animate(
        [{ transform: `translate(${dx}px, ${dy}px)` }, { transform: 'none' }],
        { duration: glyphSettleMs, easing: settleEasing },
      );
    };
  }

  const fade: Attachment<HTMLElement> = (element) => {
    element.animate([{ opacity: 1 }, { opacity: 0 }], {
      duration: glyphSettleMs / 3,
      fill: 'forwards',
    });
  };

  let width = $state(0);
  let height = $state(0);
  let previous: Previous = {
    glyphs: [],
    target: [],
    start: [],
    appearing: [],
    began: 0,
    width: 0,
    height: 0,
  };

  const measureSize: Attachment<HTMLElement> = (element) => {
    const observer = new ResizeObserver(([entry]) => {
      if (!entry) return;
      width = entry.contentRect.width;
      height = entry.contentRect.height;
    });
    observer.observe(element);
    return () => observer.disconnect();
  };

  const area = $derived<Frame>({
    x: padding,
    y: padding * 0.75,
    width: Math.max(0, width - padding * 2),
    height: Math.max(0, height - padding * 1.5),
  });

  function layout(list: G[]): { frames: Frame[]; window: Frame } {
    if (area.width <= 0 || list.length === 0)
      return {
        frames: list.map(() => ({ x: 0, y: 0, width: 0, height: 0 })),
        window: area,
      };
    const pitch = metrics.height + metrics.rowGap;
    const { frames, rows } = glyphRows(
      list.map(measure),
      list.map(kind),
      area.width,
      metrics.gap,
      metrics.height,
      pitch,
    );
    const fit = Math.max(1, Math.floor((area.height + metrics.rowGap) / pitch));
    const focusFrame = focus === undefined ? undefined : frames[focus];
    const focusRow =
      focusFrame === undefined
        ? undefined
        : Math.round(focusFrame.y / pitch) - (fit > 2 ? 1 : 0);
    const first =
      rows <= fit
        ? 0
        : Math.min(Math.max(0, focusRow ?? rows - fit), rows - fit);
    const block = Math.min(rows, fit) * pitch - metrics.rowGap;
    const y = area.y + Math.max(0, (area.height - block) / 2) - first * pitch;
    const widest = Math.max(0, ...frames.map((f) => f.x + f.width));
    const x = rows === 1 ? area.x + (area.width - widest) / 2 : area.x;
    return {
      frames: frames.map((f) => ({ ...f, x: f.x + x, y: f.y + y })),
      window: {
        x: 0,
        y: y + first * pitch - metrics.rowGap / 2,
        width,
        height: block + metrics.rowGap,
      },
    };
  }

  const scene = $derived.by(() => {
    const now = performance.now();
    const progress = Math.min(1, (now - previous.began) / glyphSettleMs);
    const eased = glyphEased(progress);
    const shown = previous.target.map((to, i) => {
      const from = previous.start[i];
      if (progress >= 1 || !from || previous.appearing[i]) return to;
      return {
        x: from.x + (to.x - from.x) * eased,
        y: from.y + (to.y - from.y) * eased,
        width: from.width + (to.width - from.width) * eased,
        height: from.height + (to.height - from.height) * eased,
      };
    });
    const { frames: target, window } = layout(glyphs);
    const moves =
      animated !== false && previous.width > 0 && width > 0 && !still();

    const old = previous.glyphs;
    const same =
      old.length === glyphs.length &&
      old.every((g, i) => equals(g, glyphs[i]!));
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
        equals(
          old[old.length - 1 - suffix]!,
          glyphs[glyphs.length - 1 - suffix]!,
        )
      )
        suffix += 1;
      start = glyphs.map((_, i) => {
        if (i < prefix) return shown[i]!;
        if (i >= glyphs.length - suffix)
          return shown[i - glyphs.length + old.length]!;
        return target[i]!;
      });
      appearing = glyphs.map(
        (_, i) => i >= prefix && i < glyphs.length - suffix,
      );
      const bounds = { x: 0, y: 0, width, height };
      for (let i = prefix; i < old.length - suffix; i++) {
        const frame = shown[i];
        if (frame && frame.width > 0 && intersects(frame, bounds))
          ghosts.push({ glyph: old[i]!, style: box(frame) });
      }
      animating = true;
    } else if (same && moves) {
      const resettles =
        focus !== previous.focus ||
        (progress < 1 &&
          (metrics !== previous.metrics ||
            width !== previous.width ||
            height !== previous.height));
      if (resettles && shown.length === target.length) {
        start = shown;
        animating = true;
      }
    }
    if (!animating) ghosts = [];

    // the last scene is animation memory: frames to slide from, not rendered state
    previous = {
      glyphs,
      target,
      start,
      appearing,
      began: animating ? now : previous.began,
      width,
      height,
      metrics,
      focus,
    };

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
    const bottom = height - (window.y + window.height);
    return {
      items,
      ghosts,
      empty: glyphs.length === 0,
      clip: `clip-path: inset(${window.y}px 0 ${bottom}px 0)`,
      area: box(area),
    };
  });
</script>

<!--
  @component
  A transliteration drawn as glyphs in wrapped rows, the last row in view:
  the banner of the text tools. On a change the glyphs that match at the
  start and the end slide to their new places, new ones grow in and removed
  ones fade.
-->
<div
  class={['canon-glyph-flow', className]}
  role="img"
  aria-label={label}
  {@attach measureSize}
  {...rest}
>
  {#if scene.empty}
    <div class="canon-glyph-flow-empty" style={scene.area}>
      {@render empty?.()}
    </div>
  {/if}
  <div class="canon-glyph-flow-glyphs" style={scene.clip} aria-hidden="true">
    {#each scene.ghosts as ghost (ghost)}
      <div class="canon-glyph-flow-glyph" style={ghost.style} {@attach fade}>
        {@render children?.(ghost.glyph, null)}
      </div>
    {/each}
    {#each scene.items as item (item.index)}
      <div
        class="canon-glyph-flow-glyph"
        style={item.style}
        {@attach glide(item)}
      >
        {@render children?.(item.glyph, item.index)}
      </div>
    {/each}
  </div>
</div>
