<script setup lang="ts">
import { computed, type Component } from 'vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-sidebar-row.css';

/** neutral: no state. off: disabled module. on and warning light the leading edge. */
export type CanonSidebarLight = 'neutral' | 'off' | 'on' | 'warning';

const props = defineProps<{
  title: string;
  /** Rendered in the 44 px icon cell; the consumer supplies it. */
  icon?: Component;
  /** Default neutral. */
  light?: CanonSidebarLight;
  /** The current page: filled in primary, `aria-current="page"`. */
  selected?: boolean;
  /** Makes the row a link; without it the row is a button. */
  href?: string;
  onClick?: (event: MouseEvent) => void;
}>();

const light = computed(() => props.light ?? 'neutral');
const current = computed(() => (props.selected ? 'page' : undefined));

function click(event: MouseEvent) {
  props.onClick?.(event);
}
</script>

<!-- One navigation row of a CanonSidebar: an icon cell and a title cell (SidebarRow). -->
<template>
  <a
    v-if="href"
    :href="href"
    class="canon-sidebar-row"
    :class="`canon-sidebar-row--${light}`"
    :aria-current="current"
    @click="click"
  >
    <span class="canon-sidebar-row-icon" aria-hidden="true">
      <component :is="icon" v-if="icon" />
    </span>
    <span class="canon-sidebar-row-title">{{ title }}</span>
  </a>
  <button
    v-else
    type="button"
    class="canon-sidebar-row"
    :class="`canon-sidebar-row--${light}`"
    :aria-current="current"
    @click="click"
  >
    <span class="canon-sidebar-row-icon" aria-hidden="true">
      <component :is="icon" v-if="icon" />
    </span>
    <span class="canon-sidebar-row-title">{{ title }}</span>
  </button>
</template>
