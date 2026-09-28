<script lang="ts">
export const pane = 'main';
export const order = 40;
</script>

<script setup lang="ts">
import { ref } from 'vue';
import CanonColourWell from '../../../src/components/canon-colour-well.vue';
import CanonHeading from '../../../src/components/canon-heading.vue';
import CanonRows from '../../../src/components/canon-rows.vue';
import type { Rgb } from '@canon/lib/colour.ts';

const foreground = ref<Rgb>([0.118, 0.4, 0.149]);
const orange = ref<Rgb>([1, 0.584, 0]);
</script>

<template>
  <CanonRows :framed="true">
    <CanonHeading text="Wells" />
    <CanonColourWell
      label="Foreground"
      :colour="foreground"
      format="oklch"
      :on-change="(colour: Rgb) => (foreground = colour)"
    />
    <CanonColourWell
      :colour="orange"
      :on-change="(colour: Rgb) => (orange = colour)"
    />
  </CanonRows>
</template>
