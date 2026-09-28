<script lang="ts">
export type CanonStatusTone = 'ok' | 'warn' | 'muted';
</script>

<script setup lang="ts">
import '@canon/styles/tokens.css';
import '@canon/components/canon-status.css';

defineProps<{
  text: string;
  tone: CanonStatusTone;
  /** A padded row of its own for a CanonRows. */
  row?: boolean;
}>();
</script>

<!-- A short state word in the colour of its tone: ok, warn or muted. -->
<template>
  <div
    class="canon-status"
    :class="[`canon-status--${tone}`, { 'canon-status--row': row }]"
    role="status"
  >
    {{ text }}
  </div>
</template>
