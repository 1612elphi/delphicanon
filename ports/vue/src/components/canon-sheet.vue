<script lang="ts">
export type CanonSheetEdge = 'start' | 'end' | 'top' | 'bottom';

const offsets: Record<CanonSheetEdge, string> = {
  top: 'translateY(-100%)',
  bottom: 'translateY(100%)',
  start: 'translateX(-100%)',
  end: 'translateX(100%)',
};
</script>

<script setup lang="ts">
import { computed } from 'vue';
import CanonDialog, { type CanonDialogClose } from './canon-dialog.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-sheet.css';

const props = withDefaults(
  defineProps<{
    open: boolean;
    title?: string;
    message?: string;
    /** Escape and a click on the backdrop close it; default true. */
    dismissable?: boolean;
    onClose?: (returnValue: string) => void;
    /** The edge it slides in from; start and end follow the writing direction. Default bottom. */
    edge?: CanonSheetEdge;
  }>(),
  { dismissable: undefined },
);

defineSlots<{
  header?: (props: { close: CanonDialogClose }) => unknown;
  default?: (props: { close: CanonDialogClose }) => unknown;
  footer?: (props: { close: CanonDialogClose }) => unknown;
}>();

const edge = computed(() => props.edge ?? 'bottom');

function keyframes(dialog: HTMLDialogElement): Keyframe[] {
  let from = edge.value;
  if (getComputedStyle(dialog).direction === 'rtl')
    from = from === 'start' ? 'end' : from === 'end' ? 'start' : from;
  return [{ transform: offsets[from] }, { transform: 'none' }];
}
</script>

<!--
  CanonDialog anchored to an edge of the window, sliding in from it: the
  iOS sheet at the bottom, a side panel at start or end.
-->
<template>
  <CanonDialog
    class="canon-sheet"
    :class="`canon-sheet--${edge}`"
    :open="open"
    :title="title"
    :message="message"
    :dismissable="dismissable"
    :on-close="onClose"
    :keyframes="keyframes"
  >
    <template v-if="$slots.header" #header="{ close }">
      <slot name="header" :close="close" />
    </template>
    <template v-if="$slots.default" #default="{ close }">
      <slot :close="close" />
    </template>
    <template v-if="$slots.footer" #footer="{ close }">
      <slot name="footer" :close="close" />
    </template>
  </CanonDialog>
</template>
