import Component from '@glimmer/component';
import { service } from '@ember/service';
import { modifier } from 'ember-modifier';
import type CanonToastService from '../services/canon-toast.ts';
import { springEasing } from '../lib/motion.ts';
import { placeToast, type Box } from '../lib/toast.ts';
import '../styles/tokens.css';
import './canon-toast.css';

export interface CanonToastSignature {
  Element: HTMLDivElement;
}

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

/**
 * The toast outlet. Render it once, near the root of the app; the
 * canon-toast service shows it. It fades in, stays 1.4 s after the last show
 * and fades out; a show while visible bumps it.
 */
export default class CanonToast extends Component<CanonToastSignature> {
  @service('canon-toast') declare toast: CanonToastService;

  /** Changes on every show, so a screen reader reads each one. */
  get announcement() {
    if (!this.toast.visible) return '';
    return this.toast.shown % 2 ? 'Copied' : 'Copied\u00a0';
  }

  present = modifier(
    (element: HTMLElement, [shown, visible]: [number, boolean]) => {
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
      const pointer = this.toast.lastPointer;
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
    },
  );

  <template>
    <div class="canon-toast-live" role="status">{{this.announcement}}</div>
    <div
      class="canon-toast"
      aria-hidden="true"
      {{this.present this.toast.shown this.toast.visible}}
      ...attributes
    >
      <div class="canon-toast-note">
        <svg
          class="canon-toast-check"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2.5"
          stroke-linecap="round"
          stroke-linejoin="round"
        ><path d="M20 6 9 17l-5-5" /></svg>
        <span class="canon-toast-title">Copied</span>
        {{#if this.toast.detail}}
          <span class="canon-toast-detail">{{this.toast.detail}}</span>
        {{/if}}
      </div>
    </div>
  </template>
}
