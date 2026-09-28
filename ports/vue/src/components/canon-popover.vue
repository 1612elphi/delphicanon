<script setup lang="ts">
import { shallowRef, useId, useTemplateRef, watch } from 'vue';
import { attach, hide, type CanonPlacement } from '@canon/lib/popover.ts';
import { elementOf, type CanonTriggerRef } from '../lib/trigger.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-popover.css';

defineOptions({ inheritAttrs: false });

const props = defineProps<{
  /** Default bottom-start. The panel flips to the other side when it does not fit. */
  placement?: CanonPlacement;
}>();

defineSlots<{
  /** Bind `trigger` as the ref of the button that opens the panel. */
  trigger?: (props: { trigger: CanonTriggerRef; close: () => void }) => unknown;
  content?: (props: { close: () => void }) => unknown;
}>();

const id = `${useId()}-popover`;
const panelRef = useTemplateRef<HTMLElement>('panel');
const anchor = shallowRef<HTMLElement | null>(null);

const trigger: CanonTriggerRef = (target) => {
  anchor.value = elementOf(target);
};

watch(
  [anchor, panelRef, () => props.placement],
  ([button, panel, placement], _, onCleanup) => {
    if (!button || !panel) return;
    onCleanup(
      attach(panel, button, {
        placement: placement ?? 'bottom-start',
        invokes: true,
      }),
    );
  },
  { flush: 'post' },
);

function close() {
  if (panelRef.value) hide(panelRef.value);
}
</script>

<!--
  A panel anchored to the consumer's button. The button toggles it; a
  click outside or Escape closes it, and focus inside goes back to the
  button. Give the panel a role and a label (role="dialog" aria-label="…")
  and autofocus on what should take focus.
-->
<template>
  <slot name="trigger" :trigger="trigger" :close="close" />
  <div
    :id="id"
    ref="panel"
    class="canon-popover"
    popover="auto"
    v-bind="$attrs"
  >
    <slot name="content" :close="close" />
  </div>
</template>
