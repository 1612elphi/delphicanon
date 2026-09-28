<script setup lang="ts">
import '@canon/styles/tokens.css';
import '@canon/components/canon-preview-panel.css';

defineProps<{
  caption: string;
  /** Trailing note in the caption row, such as the size. */
  detail?: string;
}>();
</script>

<!-- Framed preview: caption row, hairline, then the content flush beneath. -->
<template>
  <figure class="canon-preview-panel">
    <figcaption class="canon-preview-panel-header">
      <span class="canon-preview-panel-caption">{{ caption }}</span>
      <span v-if="detail" class="canon-preview-panel-detail">{{ detail }}</span>
    </figcaption>
    <div class="canon-preview-panel-content"><slot /></div>
  </figure>
</template>
