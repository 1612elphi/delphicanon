<script lang="ts" module>
  import type { Attachment } from 'svelte/attachments';

  export type CanonPopoverTrigger = Attachment<HTMLButtonElement>;
</script>

<script lang="ts">
  import type { Snippet } from 'svelte';
  import type { HTMLAttributes } from 'svelte/elements';
  import {
    attach,
    hide,
    panelFor,
    type CanonPlacement,
  } from '@canon/lib/popover.ts';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-popover.css';

  interface Props extends Omit<HTMLAttributes<HTMLDivElement>, 'content'> {
    /** Default bottom-start. The panel flips to the other side when it does not fit. */
    placement?: CanonPlacement;
    /** Put `{@attach trigger}` on the button that opens the panel. */
    trigger?: Snippet<[{ trigger: CanonPopoverTrigger; close: () => void }]>;
    content?: Snippet<[{ close: () => void }]>;
  }

  let {
    placement,
    trigger: triggerBlock,
    content,
    class: className,
    ...rest
  }: Props = $props();

  const uid = $props.id();
  const id = `${uid}-popover`;
  let panel: HTMLElement | undefined;

  const trigger: CanonPopoverTrigger = (button) => {
    panel = panelFor(button, id);
    return attach(panel, button, {
      placement: placement ?? 'bottom-start',
      invokes: true,
    });
  };

  const close = () => {
    if (panel) hide(panel);
  };
</script>

<!--
  @component
  A panel anchored to the consumer's button. The button toggles it; a
  click outside or Escape closes it, and focus inside goes back to the
  button. Give the panel a role and a label (`role="dialog"
  aria-label="…"`) and `autofocus` on what should take focus.
-->
{@render triggerBlock?.({ trigger, close })}
<div {id} class={['canon-popover', className]} popover="auto" {...rest}>
  {@render content?.({ close })}
</div>
