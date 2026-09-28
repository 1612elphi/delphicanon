<script lang="ts">
export const pane = 'main';
export const order = 20;
</script>

<script setup lang="ts">
import CanonButton from '../../../src/components/canon-button.vue';
import CanonGrid from '../../../src/components/canon-grid.vue';
import CanonHeading from '../../../src/components/canon-heading.vue';
import CanonRows from '../../../src/components/canon-rows.vue';
import { toast } from '../../../src/lib/toast-store.ts';
import { icon } from '../icon.ts';
import copy from 'lucide-static/icons/copy.svg?raw';
import eraser from 'lucide-static/icons/eraser.svg?raw';
import messageSquareCheck from 'lucide-static/icons/message-square-check.svg?raw';
import play from 'lucide-static/icons/play.svg?raw';
import repeat from 'lucide-static/icons/repeat.svg?raw';
import rotateCw from 'lucide-static/icons/rotate-cw.svg?raw';
import share from 'lucide-static/icons/share.svg?raw';
import shuffle from 'lucide-static/icons/shuffle.svg?raw';
import square from 'lucide-static/icons/square.svg?raw';
import trash from 'lucide-static/icons/trash-2.svg?raw';

const showToast = () => toast.show('#3B82F6');
</script>

<template>
  <CanonRows :framed="true">
    <CanonHeading text="Classics" />
    <CanonButton text="Generate" :icon="icon(rotateCw)" kind="primary" />
    <CanonGrid>
      <CanonButton text="Copy" :icon="icon(copy)" />
      <CanonButton text="Export" :icon="icon(share)" kind="primary" />
    </CanonGrid>
    <CanonButton
      text="Generate"
      :icon="icon(rotateCw)"
      icon-style="oversized"
      kind="primary"
    />
    <CanonGrid>
      <CanonButton text="Wipe" :icon="icon(eraser)" icon-style="oversized" />
      <CanonButton text="Copy" :icon="icon(copy)" icon-style="oversized" />
      <CanonButton
        text="Export"
        :icon="icon(share)"
        icon-style="oversized"
        kind="primary"
      />
    </CanonGrid>
    <CanonGrid>
      <CanonButton text="Loop" :icon="icon(repeat)" />
      <CanonButton text="Play" :icon="icon(play)" kind="primary" />
      <CanonButton text="Stop" :icon="icon(square)" />
      <CanonButton text="Shuffle" :icon="icon(shuffle)" />
      <CanonButton text="Export" :icon="icon(share)" />
      <CanonButton text="Delete" :icon="icon(trash)" />
    </CanonGrid>
    <CanonButton
      text="Toast"
      :icon="icon(messageSquareCheck)"
      :on-click="showToast"
    />
    <CanonButton text="Copy" :icon="icon(copy)" :flashes-copied="true" />
  </CanonRows>
</template>
