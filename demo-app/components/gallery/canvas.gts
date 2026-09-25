import CanonCanvas from '#src/components/canon-canvas.gts';
import GalleryArt from '../gallery-art.gts';

export const pane = 'main';
export const order = 10;

<template>
  <CanonCanvas @aspect={{4}}><GalleryArt @label="Column canvas" /></CanonCanvas>
  <CanonCanvas @aspect={{4}} @boxing="unlessWide">
    <GalleryArt @label="Boxed unless wide" />
  </CanonCanvas>
</template>
