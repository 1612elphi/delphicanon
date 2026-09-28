<script setup lang="ts">
defineProps<{ label: string }>();
</script>

<!-- Stand-in canvas content: a gradient with a centred label. -->
<template>
  <div class="gallery-art">
    <span>{{ label }}</span>
  </div>
</template>
