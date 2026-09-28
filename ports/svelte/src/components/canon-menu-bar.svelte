<script lang="ts" module>
  import type { CanonMenuEntry } from './canon-menu-list.svelte';

  export interface CanonMenuBarMenu {
    title: string;
    items: CanonMenuEntry[];
  }
</script>

<script lang="ts">
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLAttributes } from 'svelte/elements';
  import CanonButton from './canon-button.svelte';
  import CanonGrid from './canon-grid.svelte';
  import CanonMenuList, {
    showMenu,
    type CanonMenuItem,
  } from './canon-menu-list.svelte';
  import { wrap } from '@canon/lib/menu.ts';
  import { attach, hide } from '@canon/lib/popover.ts';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-menu.css';
  import '@canon/components/canon-menu-bar.css';

  interface Props extends Omit<
    HTMLAttributes<HTMLDivElement>,
    'children' | 'onselect'
  > {
    menus: CanonMenuBarMenu[];
    /** The item, and the index of the menu it is in. */
    onSelect?: (item: CanonMenuItem, menu: number) => void;
  }

  let { menus, onSelect, class: className, ...rest }: Props = $props();

  const uid = $props.id();
  const id = `${uid}-bar`;
  /** The cell in the tab order. */
  let current = $state(0);
  let opened = $state<number>();
  let root: HTMLElement | undefined;

  const cell = (index: number) =>
    root?.querySelector<HTMLElement>(`[data-menu-cell="${index}"]`);
  const panel = (index: number) =>
    root?.querySelector<HTMLElement>(`#${id}-${index}`);
  const openPanel = () =>
    root?.querySelector<HTMLElement>(':scope > .canon-menu:popover-open');

  const setup: Attachment<HTMLElement> = (element) => {
    root = element;
    // Tab out of the bar closes its menu
    const focusout = (event: FocusEvent) => {
      const next = event.relatedTarget;
      const open = openPanel();
      if (open && next instanceof Node && !element.contains(next)) hide(open);
    };
    element.addEventListener('focusout', focusout);
    return () => element.removeEventListener('focusout', focusout);
  };

  // one attachment per index, so a new menus array does not re-anchor an open menu
  const anchors: Attachment<HTMLElement>[] = [];
  function anchor(index: number): Attachment<HTMLElement> {
    let attachment = anchors[index];
    if (!attachment) {
      attachment = (list) => {
        const button = list.parentElement?.querySelector<HTMLElement>(
          `[data-menu-cell="${index}"]`,
        );
        if (!button) return;
        const detach = attach(list, button, {
          placement: 'bottom-start',
          invokes: true,
        });
        button.setAttribute('aria-haspopup', 'menu');
        const toggle = (event: ToggleEvent) => {
          if (event.newState === 'open') opened = index;
          else if (opened === index) opened = undefined;
        };
        list.addEventListener('toggle', toggle);
        return () => {
          list.removeEventListener('toggle', toggle);
          button.removeAttribute('aria-haspopup');
          detach();
        };
      };
      anchors[index] = attachment;
    }
    return attachment;
  }

  /** Focus a cell; if a menu is open, the cell's menu replaces it with focus left on the cell. */
  function move(to: number) {
    const list = panel(to);
    if (list && openPanel()) showMenu(list, 'none');
    cell(to)?.focus({ preventScroll: true });
  }

  function cellKey(index: number, event: KeyboardEvent) {
    const count = menus.length;
    const rtl = (event.currentTarget as Element).matches(':dir(rtl)');
    const list = panel(index);
    switch (event.key) {
      case rtl ? 'ArrowLeft' : 'ArrowRight':
        move(wrap(index, 1, count));
        break;
      case rtl ? 'ArrowRight' : 'ArrowLeft':
        move(wrap(index, -1, count));
        break;
      case 'Home':
        move(0);
        break;
      case 'End':
        move(count - 1);
        break;
      // Enter and Space would toggle through popovertarget and close an open menu
      case 'ArrowDown':
      case 'Enter':
      case ' ':
        if (list) showMenu(list, 'first');
        break;
      case 'ArrowUp':
        if (list) showMenu(list, 'last');
        break;
      default:
        return;
    }
    event.preventDefault();
  }

  function hover(index: number, event: PointerEvent) {
    if (event.pointerType === 'touch') return;
    const open = openPanel();
    if (open && open !== panel(index)) move(index);
  }

  function edge(index: number, step: 1 | -1) {
    const to = wrap(index, step, menus.length);
    const list = panel(to);
    if (list) showMenu(list, 'none');
    cell(to)?.focus({ preventScroll: true });
  }
</script>

<!--
  @component
  A row of flush cells, each opening a menu. While one is open, the
  pointer over another cell or the inline arrow keys move to its menu, as
  in the macOS menu bar. Give it an `aria-label`.
-->
<div
  class={['canon-menu-bar', className]}
  role="menubar"
  {@attach setup}
  {...rest}
>
  <CanonGrid class="canon-menu-bar-cells">
    {#each menus as menu, index (index)}
      <CanonButton
        class={[
          'canon-menu-bar-cell',
          index === opened && 'canon-menu-bar-cell--open',
        ]}
        role="menuitem"
        tabindex={index === current ? 0 : -1}
        data-menu-cell={index}
        kind="cell"
        text={menu.title}
        onkeydown={(event) => cellKey(index, event)}
        onpointerenter={(event) => hover(index, event)}
        onfocus={() => (current = index)}
      />
    {/each}
  </CanonGrid>
  {#each menus as menu, index (index)}
    <CanonMenuList
      id="{id}-{index}"
      items={menu.items}
      onSelect={(item) => onSelect?.(item, index)}
      onEdge={(step) => edge(index, step)}
      {@attach anchor(index)}
    />
  {/each}
</div>
