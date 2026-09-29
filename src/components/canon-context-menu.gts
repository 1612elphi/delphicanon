import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';
import {
  CanonMenuList,
  showMenu,
  type CanonMenuEntry,
  type CanonMenuItem,
} from './canon-menu.gts';
import { afterPress, attach, isOpen } from '../lib/popover.ts';
import '../styles/tokens.css';
import './canon-context-menu.css';

export interface CanonContextMenuSignature {
  Args: {
    items: CanonMenuEntry[];
    onSelect?: (item: CanonMenuItem) => void;
  };
  /** The area the menu belongs to. */
  Blocks: { default: [] };
  Element: HTMLDivElement;
}

/**
 * A menu opened at the pointer by a secondary click in the area, or below
 * the focused element by Shift+F10 or the context menu key. Focus goes
 * back to where it was when the menu closes.
 */
export default class CanonContextMenu extends Component<CanonContextMenuSignature> {
  #returnTo: Element | null = null;

  setup = modifier((root: HTMLElement) => {
    // the last two children, after the consumer's block
    const panel = root.lastElementChild as HTMLElement;
    const point = panel.previousElementSibling as HTMLElement;
    const detach = attach(panel, point, {
      placement: 'bottom-start',
      gap: '0px',
      returnFocus: () => this.#returnTo,
    });

    // client coordinates are physical, so left and top
    const openAt = (x: number, y: number) => {
      this.#returnTo = document.activeElement;
      point.style.left = `${x}px`;
      point.style.top = `${y}px`;
      showMenu(panel, 'first');
    };
    const below = (element: Element) => {
      const box = element.getBoundingClientRect();
      openAt(element.matches(':dir(rtl)') ? box.right : box.left, box.bottom);
    };
    const contextmenu = (event: MouseEvent) => {
      event.preventDefault();
      // the key already opened it, or the click is on the menu itself
      if (isOpen(panel)) return;
      // a context menu key the keydown did not see reports no position
      if (event.clientX === 0 && event.clientY === 0)
        below(event.target as Element);
      else {
        const { clientX, clientY } = event;
        afterPress(event.buttons !== 0, () => openAt(clientX, clientY));
      }
    };
    const keydown = (event: KeyboardEvent) => {
      const key =
        event.key === 'ContextMenu' || (event.shiftKey && event.key === 'F10');
      if (!key || panel.contains(event.target as Node)) return;
      event.preventDefault();
      below(event.target as Element);
    };
    root.addEventListener('contextmenu', contextmenu);
    root.addEventListener('keydown', keydown);
    return () => {
      root.removeEventListener('contextmenu', contextmenu);
      root.removeEventListener('keydown', keydown);
      detach();
    };
  });

  select = (item: CanonMenuItem) => this.args.onSelect?.(item);

  <template>
    <div class="canon-context-menu" {{this.setup}} ...attributes>
      {{yield}}
      <span class="canon-context-menu-point" aria-hidden="true"></span>
      <CanonMenuList @items={{@items}} @onSelect={{this.select}} />
    </div>
  </template>
}
