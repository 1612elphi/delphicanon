<script lang="ts">
  import type { Snippet } from 'svelte';
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLAttributes } from 'svelte/elements';
  import CanonMenuList, {
    showMenu,
    type CanonMenuEntry,
    type CanonMenuItem,
  } from './canon-menu-list.svelte';
  import { attach, isOpen } from '@canon/lib/popover.ts';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-menu.css';
  import '@canon/components/canon-context-menu.css';

  interface Props extends Omit<HTMLAttributes<HTMLDivElement>, 'onselect'> {
    items: CanonMenuEntry[];
    onSelect?: (item: CanonMenuItem) => void;
    /** The area the menu belongs to. */
    children?: Snippet;
  }

  let {
    items,
    onSelect,
    children,
    class: className,
    ...rest
  }: Props = $props();

  let returnTo: Element | null = null;

  const setup: Attachment<HTMLElement> = (root) => {
    // the last two children, after the consumer's block
    const panel = root.lastElementChild as HTMLElement;
    const point = panel.previousElementSibling as HTMLElement;
    const detach = attach(panel, point, {
      placement: 'bottom-start',
      gap: '0px',
      returnFocus: () => returnTo,
    });

    // client coordinates are physical, so left and top
    const openAt = (x: number, y: number) => {
      returnTo = document.activeElement;
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
      else openAt(event.clientX, event.clientY);
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
  };

  const select = (item: CanonMenuItem) => onSelect?.(item);
</script>

<!--
  @component
  A menu opened at the pointer by a secondary click in the area, or below
  the focused element by Shift+F10 or the context menu key. Focus goes
  back to where it was when the menu closes.
-->
<div class={['canon-context-menu', className]} {@attach setup} {...rest}>
  {@render children?.()}
  <span class="canon-context-menu-point" aria-hidden="true"></span>
  <CanonMenuList {items} onSelect={select} />
</div>
