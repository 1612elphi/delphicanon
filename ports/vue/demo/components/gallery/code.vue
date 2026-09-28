<script lang="ts">
export const pane = 'main';
export const order = 22;
</script>

<script setup lang="ts">
import CanonCodeBlock from '../../../src/components/canon-code-block.vue';
import CanonHeading from '../../../src/components/canon-heading.vue';
import CanonRows from '../../../src/components/canon-rows.vue';

const css = `.button {
    border-radius: 0;
    color: oklch(0.45 0.12 145);
}`;
const plain = 'no language: copy sits below';
const long = Array.from(
  { length: 400 },
  (_, i) => `line ${i + 1}: ${'lorem ipsum '.repeat(12)}`,
).join('\n');
</script>

<template>
  <CanonRows :framed="true">
    <CanonHeading text="Code" />
    <CanonCodeBlock :code="css" language="css" />
    <CanonCodeBlock :code="plain" />
    <CanonCodeBlock :code="long" language="capped at 160" :max-height="160" />
  </CanonRows>
</template>
