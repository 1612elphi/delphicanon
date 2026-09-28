import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { hash } from '@ember/helper';
import { modifier } from 'ember-modifier';
import type { ModifierLike } from '@glint/template';
import {
  attach,
  hide,
  isOpen,
  panelFor,
  type CanonPlacement,
} from '../lib/popover.ts';
import '../styles/tokens.css';
import './canon-popover.css';
import './canon-tooltip.css';

export interface CanonTooltipSignature {
  Args: {
    text: string;
    /** Default top. */
    placement?: CanonPlacement;
  };
  /** Put `trigger` on the element the hint describes. */
  Blocks: { default: [{ trigger: ModifierLike<{ Element: HTMLElement }> }] };
  Element: HTMLDivElement;
}

/** The pointer may cross the gap onto the hint in this many ms before it hides. */
export const tooltipGraceMs = 100;

function describe(element: Element, id: string, on: boolean) {
  const ids = (element.getAttribute('aria-describedby') ?? '')
    .split(/\s+/)
    .filter((other) => other && other !== id);
  if (on) ids.push(id);
  if (ids.length) element.setAttribute('aria-describedby', ids.join(' '));
  else element.removeAttribute('aria-describedby');
}

/**
 * A hint shown while the pointer is over the trigger or keyboard focus is
 * on it. Escape and a press hide it.
 */
export default class CanonTooltip extends Component<CanonTooltipSignature> {
  id = `${guidFor(this)}-tooltip`;

  trigger = modifier((element: HTMLElement) => {
    const tip = panelFor(element, this.id);
    const detach = attach(tip, element, {
      placement: this.args.placement ?? 'top',
    });
    describe(element, this.id, true);
    let leaving: number | undefined;

    const show = () => {
      window.clearTimeout(leaving);
      if (!isOpen(tip)) tip.showPopover();
    };
    const hideNow = () => {
      window.clearTimeout(leaving);
      hide(tip);
    };
    const hideSoon = () => {
      window.clearTimeout(leaving);
      leaving = window.setTimeout(() => hide(tip), tooltipGraceMs);
    };
    const enter = (event: PointerEvent) => {
      if (event.pointerType !== 'touch') show();
    };
    // a click focuses the trigger without :focus-visible, and should not bring the hint back
    const focus = () => {
      if (element.matches(':focus-visible')) show();
    };
    const escape = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && isOpen(tip)) hideNow();
    };

    const listeners = [
      [element, 'pointerenter', enter],
      [element, 'pointerleave', hideSoon],
      [element, 'pointerdown', hideNow],
      [element, 'focusin', focus],
      [element, 'focusout', hideNow],
      [tip, 'pointerenter', show],
      [tip, 'pointerleave', hideSoon],
      [document, 'keydown', escape],
    ] as const;
    for (const [target, type, listener] of listeners)
      target.addEventListener(type, listener as EventListener);
    return () => {
      window.clearTimeout(leaving);
      for (const [target, type, listener] of listeners)
        target.removeEventListener(type, listener as EventListener);
      describe(element, this.id, false);
      detach();
    };
  });

  <template>
    {{yield (hash trigger=this.trigger)}}
    <div
      id={{this.id}}
      class="canon-popover canon-tooltip"
      popover="manual"
      role="tooltip"
      ...attributes
    >{{@text}}</div>
  </template>
}
