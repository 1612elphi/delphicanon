<script lang="ts">
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLAttributes } from 'svelte/elements';
  import { springEasing } from '@canon/lib/motion.ts';
  import { placeToast, type Box } from '@canon/lib/toast.ts';
  import { canonToast as toast } from '../lib/toast-store.svelte.ts';
  import { check } from '../lib/control-icons.ts';
  import CanonIcon from './canon-icon.svelte';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-toast.css';

  let { class: className, ...rest }: HTMLAttributes<HTMLDivElement> = $props();

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

  // changes on every show, so a screen reader reads each one
  const announcement = $derived(
    toast.visible ? (toast.shown % 2 ? 'Copied' : 'Copied ') : '',
  );

  function present(shown: number, visible: boolean): Attachment<HTMLElement> {
    return (element) => {
      const note = element.firstElementChild as HTMLElement | null;
      if (shown === 0 || !note) return;
      const still = window.matchMedia(
        '(prefers-reduced-motion: reduce)',
      ).matches;
      const showing = element.style.opacity === '1';
      if (!visible) {
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
    };
  }
</script>

<!--
  @component
  The toast outlet. Render it once, near the root of the app; `canonToast`
  from `lib/toast-store.svelte.ts` shows it. It fades in, stays 1.4 s after
  the last show and fades out; a show while visible bumps it.
-->
<div class="canon-toast-live" role="status">{announcement}</div>
<div
  class={['canon-toast', className]}
  aria-hidden="true"
  {@attach present(toast.shown, toast.visible)}
  {...rest}
>
  <div class="canon-toast-note">
    <span class="canon-toast-check"><CanonIcon svg={check} /></span>
    <span class="canon-toast-title">Copied</span>
    {#if toast.detail}
      <span class="canon-toast-detail">{toast.detail}</span>
    {/if}
  </div>
</div>
