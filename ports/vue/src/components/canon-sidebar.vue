<script setup lang="ts">
import { computed } from 'vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-sidebar.css';

const props = withDefaults(
  defineProps<{
    /**
     * true: the icon rail. false: full width at every size. Unset: the rail
     * inside a `canon-window` container narrower than 640 px.
     */
    collapsed?: boolean;
  }>(),
  { collapsed: undefined },
);

defineSlots<{
  /** A picture above the rows that does not scroll with them. */
  hero?: () => unknown;
  /** CanonSidebarRows, and CanonHeadings between groups. */
  default?: () => unknown;
}>();

const state = computed(() => {
  if (props.collapsed === true) return 'canon-sidebar--collapsed';
  if (props.collapsed === false) return 'canon-sidebar--expanded';
  return undefined;
});
</script>

<!--
  The window's navigation column (Sidebar): 240 px of 44 px rows on the
  muted background, the gaps between rows and cells showing the border
  colour, a frame-width rule on the trailing edge.
-->
<template>
  <nav class="canon-sidebar" :class="state">
    <div v-if="$slots.hero" class="canon-sidebar-hero">
      <slot name="hero" />
    </div>
    <div class="canon-sidebar-scroll">
      <div class="canon-sidebar-rows"><slot /></div>
    </div>
  </nav>
</template>
