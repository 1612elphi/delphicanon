import { pageTitle } from 'ember-page-title';
import CanonToast from '#src/components/canon-toast.gts';
import ColourPage from '../components/colour-page.gts';
import Gallery from '../components/gallery.gts';
import PaperSizes from '../components/tools/paper-sizes/paper-sizes.gts';

// ?page=colour: the colour page, as CanonColourGalleryViewController; ?page=paper-sizes: the paper sizes tool
const page = new URLSearchParams(window.location.search).get('page');
const colour = page === 'colour';
const paperSizes = page === 'paper-sizes';

<template>
  {{pageTitle "Canon"}}
  {{#if colour}}
    <ColourPage />
  {{else if paperSizes}}
    <PaperSizes />
  {{else}}
    <Gallery />
  {{/if}}
  <CanonToast />
</template>
