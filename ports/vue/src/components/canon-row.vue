<script setup lang="ts">
import { computed, useId, type Component } from 'vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-row.css';

export type CanonRowForm = 'plain' | 'flush' | 'stacked';

const props = defineProps<{
  title: string;
  detail?: string;
  /** Shown before the title in a plain row. */
  icon?: Component;
  /**
   * plain: the control keeps air around it. flush: the control meets the
   * row's top, bottom and trailing edge behind a hairline. stacked: the
   * control spans the row below the label.
   */
  form?: CanonRowForm;
  /** Longest title among sibling rows, so a grid of rows stacks as one. */
  sizingTitle?: string;
}>();

defineSlots<{
  /** The control; gets the title's id for aria-labelledby. */
  default?: (props: { titleId: string }) => unknown;
}>();

const titleId = `${useId()}-title`;
const form = computed(() => props.form ?? 'plain');
const showsIcon = computed(
  () => props.icon !== undefined && form.value === 'plain',
);
</script>

<!--
  Label beside a control. A row too narrow for both puts the control below
  the label.
-->
<template>
  <div class="canon-row" :class="`canon-row--${form}`">
    <div class="canon-row-label">
      <span v-if="showsIcon" class="canon-row-icon" aria-hidden="true">
        <component :is="icon" />
      </span>
      <div class="canon-row-text">
        <span :id="titleId" class="canon-row-title">{{ title }}</span>
        <span v-if="detail" class="canon-row-detail">{{ detail }}</span>
        <span
          v-if="sizingTitle"
          class="canon-row-title canon-row-sizer"
          aria-hidden="true"
          >{{ sizingTitle }}</span
        >
      </div>
    </div>
    <div v-if="$slots.default" class="canon-row-control">
      <slot :title-id="titleId" />
    </div>
  </div>
</template>
