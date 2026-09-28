<script setup lang="ts">
import { computed, useId } from 'vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-window.css';

const props = defineProps<{
  title?: string;
  /** Any of the three shows all three controls; one without a callback is disabled. */
  onClose?: () => void;
  onMinimise?: () => void;
  onZoom?: () => void;
  /** Draws the 2 px tool frame around the window. */
  framed?: boolean;
}>();

defineSlots<{
  /** Trailing controls in the title bar. */
  toolbar?: () => unknown;
  /** A strip under the title bar. */
  menubar?: () => unknown;
  /** A CanonSidebar; it collapses to its rail when the body is narrower than 640 px. */
  sidebar?: () => unknown;
  /** The detail: a CanonPage or CanonSplit fills it. */
  main?: () => unknown;
}>();

const titleId = `${useId()}-title`;
const labelledBy = computed(() => (props.title ? titleId : undefined));
const controls = computed(
  () =>
    props.onClose !== undefined ||
    props.onMinimise !== undefined ||
    props.onZoom !== undefined,
);
</script>

<!--
  Desktop-style window chrome (MainWindow): a title bar, an optional menu
  bar, then the sidebar beside the detail. Fills its container.
-->
<template>
  <section
    class="canon-window"
    :class="{ 'canon-window--framed': framed }"
    :aria-labelledby="labelledBy"
  >
    <header class="canon-window-bar">
      <div v-if="controls" class="canon-window-controls">
        <button
          type="button"
          class="canon-window-control canon-window-control--close"
          aria-label="Close"
          :disabled="!onClose"
          @click="onClose?.()"
        />
        <button
          type="button"
          class="canon-window-control canon-window-control--minimise"
          aria-label="Minimise"
          :disabled="!onMinimise"
          @click="onMinimise?.()"
        />
        <button
          type="button"
          class="canon-window-control canon-window-control--zoom"
          aria-label="Zoom"
          :disabled="!onZoom"
          @click="onZoom?.()"
        />
      </div>
      <div :id="titleId" class="canon-window-title">{{ title }}</div>
      <div v-if="$slots.toolbar" class="canon-window-toolbar">
        <slot name="toolbar" />
      </div>
    </header>
    <div v-if="$slots.menubar" class="canon-window-menubar">
      <slot name="menubar" />
    </div>
    <div class="canon-window-body">
      <slot name="sidebar" />
      <div class="canon-window-main"><slot name="main" /></div>
    </div>
  </section>
</template>
