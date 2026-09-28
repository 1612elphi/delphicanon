<script setup lang="ts">
import type { Component } from 'vue';
import CanonButton from '../../src/components/canon-button.vue';
import CanonCanvas from '../../src/components/canon-canvas.vue';
import CanonGrid from '../../src/components/canon-grid.vue';
import CanonSplit from '../../src/components/canon-split.vue';
import GalleryArt from './gallery-art.vue';
import { icon } from './icon.ts';
import play from 'lucide-static/icons/play.svg?raw';
import repeat from 'lucide-static/icons/repeat.svg?raw';
import square from 'lucide-static/icons/square.svg?raw';

interface GalleryGroup {
  default: Component;
  pane: 'sidebar' | 'main';
  order: number;
}

const groups = Object.entries(
  import.meta.glob<GalleryGroup>('./gallery/*.vue', { eager: true }),
)
  .sort(([a, x], [b, y]) => x.order - y.order || a.localeCompare(b))
  .map(([, group]) => group);

const sidebar = groups
  .filter((g) => g.pane === 'sidebar')
  .map((g) => g.default);
const main = groups.filter((g) => g.pane === 'main').map((g) => g.default);

// ?halves: equal panes without a crease, as -galleryHalves on iOS
const halves = new URLSearchParams(window.location.search).has('halves');
</script>

<!-- The port of CanonGalleryViewController: one split, groups from ./gallery/. -->
<template>
  <CanonSplit class="gallery" :halves="halves">
    <template #banner>
      <CanonCanvas :height="120"
        ><GalleryArt label="All columns"
      /></CanonCanvas>
    </template>
    <template #sidebar>
      <component :is="group" v-for="(group, i) in sidebar" :key="i" />
    </template>
    <template #main>
      <component :is="group" v-for="(group, i) in main" :key="i" />
    </template>
    <template #footer>
      <CanonGrid>
        <CanonButton text="Loop" :icon="icon(repeat)" />
        <CanonButton text="Play" :icon="icon(play)" kind="primary" />
        <CanonButton text="Stop" :icon="icon(square)" />
      </CanonGrid>
    </template>
  </CanonSplit>
</template>
