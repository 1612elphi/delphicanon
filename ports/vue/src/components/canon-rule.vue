<script setup lang="ts">
import '@canon/styles/tokens.css';
import '@canon/components/canon-rule.css';

defineProps<{ vertical?: boolean }>();
</script>

<template>
  <div
    class="canon-rule"
    :class="{ 'canon-rule--vertical': vertical }"
    role="separator"
    :aria-orientation="vertical ? 'vertical' : 'horizontal'"
  />
</template>
