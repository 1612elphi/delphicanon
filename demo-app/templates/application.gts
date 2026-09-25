import { pageTitle } from 'ember-page-title';
import CanonToast from '#src/components/canon-toast.gts';
import ColourPage from '../components/colour-page.gts';
import Gallery from '../components/gallery.gts';

// ?page=colour: the colour page, as CanonColourGalleryViewController
const colour =
  new URLSearchParams(window.location.search).get('page') === 'colour';

<template>
  {{pageTitle "Canon"}}
  {{#if colour}}<ColourPage />{{else}}<Gallery />{{/if}}
  <CanonToast />
</template>
