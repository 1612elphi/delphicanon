<script lang="ts">
export const pane = 'sidebar';
export const order = 30;
</script>

<script setup lang="ts">
import CanonButton from '../../../src/components/canon-button.vue';
import CanonGrid from '../../../src/components/canon-grid.vue';
import CanonHeading from '../../../src/components/canon-heading.vue';
import CanonRow from '../../../src/components/canon-row.vue';
import CanonRows from '../../../src/components/canon-rows.vue';
import { icon } from '../icon.ts';
import moveHorizontal from 'lucide-static/icons/move-horizontal.svg?raw';
import zoomIn from 'lucide-static/icons/zoom-in.svg?raw';
import zoomOut from 'lucide-static/icons/zoom-out.svg?raw';
</script>

<template>
  <CanonRows :framed="true">
    <CanonHeading text="Grid" />
    <CanonRow title="Actions" form="stacked">
      <CanonGrid>
        <CanonButton text="Cancel" />
        <CanonButton text="Apply" kind="primary" />
      </CanonGrid>
    </CanonRow>
    <CanonRow title="Inline actions" form="flush">
      <CanonGrid>
        <CanonButton text="Cancel" kind="cell" />
        <CanonButton text="Apply" kind="cell" />
        <CanonButton text="Disabled" kind="cell" :disabled="true" />
      </CanonGrid>
    </CanonRow>
    <CanonRow title="Icon actions" detail="3.60 – 6.00" form="flush">
      <CanonGrid>
        <CanonButton kind="cell" :icon="icon(zoomOut)" label="Zoom out" />
        <CanonButton kind="cell" :icon="icon(zoomIn)" label="Zoom in" />
        <CanonButton
          kind="cell"
          :icon="icon(moveHorizontal)"
          label="Fit width"
        />
      </CanonGrid>
    </CanonRow>
  </CanonRows>
</template>
