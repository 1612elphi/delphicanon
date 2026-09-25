import CanonHeading from '#src/components/canon-heading.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonTiles from '#src/components/canon-tiles.gts';

export const pane = 'sidebar';
export const order = 40;

const items = [
  { label: 'Codec', value: 'AAC' },
  { label: 'Sample rate', value: '44100 Hz' },
  { label: 'Peak', value: '-4.3 dBFS', level: 0.93 },
  { label: 'RMS', value: '-13.6 dBFS', level: 0.77 },
  { label: 'Encoded with', value: 'Lavf62.12.101' },
];

<template>
  <CanonRows @framed={{true}}>
    <CanonHeading @text="Tiles" />
    <CanonTiles @items={{items}} />
  </CanonRows>
</template>
