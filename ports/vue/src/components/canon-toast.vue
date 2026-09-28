<script lang="ts">
import { springEasing } from '@canon/lib/motion.ts';
import type { Box } from '@canon/lib/toast.ts';

const bump = springEasing(0.6);

/** The column a pointer at `target` belongs to, with its bottom above a footer. */
function column(target: Element | null | undefined): Box {
  const pad = 16;
  const split = target?.closest('.canon-split');
  if (!split) {
    return {
      left: 0,
      top: 0,
      right: window.innerWidth,
      bottom: window.innerHeight - pad,
    };
  }
  const pane = target?.closest('.canon-split-pane')?.getBoundingClientRect();
  // one column: panes have no box of their own
  const box = pane && pane.width > 0 ? pane : split.getBoundingClientRect();
  let bottom = box.bottom - pad;
  const footer = split
    .querySelector('.canon-split-footer')
    ?.getBoundingClientRect();
  if (footer && footer.left < box.right && footer.right > box.left) {
    bottom = footer.top - 10;
  }
  return { left: box.left, top: box.top, right: box.right, bottom };
}
</script>

<script setup lang="ts">
import { computed, onMounted, useTemplateRef, watch } from 'vue';
import { placeToast } from '@canon/lib/toast.ts';
import { toast } from '../lib/toast-store.ts';
import { check } from '../lib/lucide.ts';
import CanonIcon from './canon-icon.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-toast.css';

defineOptions({ inheritAttrs: false });

/** Changes on every show, so a screen reader reads each one. */
const announcement = computed(() => {
  if (!toast.visible) return '';
  return toast.shown % 2 ? 'Copied' : 'Copied ';
});

const outlet = useTemplateRef<HTMLElement>('outlet');

function present() {
  const element = outlet.value;
  const note = element?.firstElementChild as HTMLElement | null | undefined;
  if (!element || toast.shown === 0 || !note) return;
  const still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const showing = element.style.opacity === '1';
  if (!toast.visible) {
    element.style.opacity = '0';
    element.animate(
      [
        { opacity: 1, transform: 'none' },
        { opacity: 0, transform: still ? 'none' : 'translateY(6px)' },
      ],
      { duration: 300, easing: 'ease-in' },
    );
    return;
  }
  const pointer = toast.lastPointer;
  const band = column(pointer?.target);
  note.style.maxWidth = `${Math.max(0, band.right - band.left - 32)}px`;
  const place = placeToast(band, note.offsetHeight, pointer);
  element.style.left = `${place.x}px`;
  element.style.top = `${place.bottom}px`;
  element.style.opacity = '1';
  if (!showing) {
    element.animate(
      [
        { opacity: 0, transform: still ? 'none' : 'translateY(10px)' },
        { opacity: 1, transform: 'none' },
      ],
      { duration: 220, easing: 'ease-out' },
    );
  } else if (!still) {
    element.animate([{ transform: 'scale(1.06)' }, { transform: 'none' }], {
      duration: 350,
      easing: bump,
    });
  }
}

onMounted(present);
watch(() => [toast.shown, toast.visible], present, { flush: 'post' });
</script>

<!--
  The toast outlet. Render it once, near the root of the app; the toast
  store shows it. It fades in, stays 1.4 s after the last show and fades
  out; a show while visible bumps it.
-->
<template>
  <div class="canon-toast-live" role="status">{{ announcement }}</div>
  <div ref="outlet" class="canon-toast" aria-hidden="true" v-bind="$attrs">
    <div class="canon-toast-note">
      <span class="canon-toast-check"><CanonIcon :svg="check" /></span>
      <span class="canon-toast-title">Copied</span>
      <span v-if="toast.detail" class="canon-toast-detail">{{
        toast.detail
      }}</span>
    </div>
  </div>
</template>
