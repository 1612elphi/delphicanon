<script lang="ts">
export const pane = 'sidebar';
export const order = 45;
</script>

<script setup lang="ts">
import CanonJumpHeading from '../../../src/components/canon-jump-heading.vue';
import CanonRow from '../../../src/components/canon-row.vue';
import CanonRows from '../../../src/components/canon-rows.vue';
import CanonSwitch from '../../../src/components/canon-switch.vue';
</script>

<template>
  <CanonRows :framed="true">
    <CanonJumpHeading text="Rows" detail="2" />
    <CanonRow v-slot="{ titleId }" title="Plain">
      <CanonSwitch :on="true" :aria-labelledby="titleId" />
    </CanonRow>
    <CanonRow title="No control" />
    <CanonJumpHeading text="Components" detail="2" />
    <CanonRow v-slot="{ titleId }" title="Images">
      <CanonSwitch :on="true" :aria-labelledby="titleId" />
    </CanonRow>
    <CanonRow v-slot="{ titleId }" title="Files">
      <CanonSwitch :aria-labelledby="titleId" />
    </CanonRow>
    <CanonJumpHeading text="Big number" detail="1" />
    <CanonRow v-slot="{ titleId }" title="Sound">
      <CanonSwitch :aria-labelledby="titleId" />
    </CanonRow>
  </CanonRows>
</template>
