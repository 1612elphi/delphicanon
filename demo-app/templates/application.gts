import { pageTitle } from 'ember-page-title';
import CanonToast from '#src/components/canon-toast.gts';
import ColourPage from '../components/colour-page.gts';
import Gallery from '../components/gallery.gts';
import Tools from '../components/tools.gts';

// ?page=colour: the colour page, as CanonColourGalleryViewController; ?page=tools#<id>: the tools
// shell; ?page=<id> opens that tool in it
const page = new URLSearchParams(window.location.search).get('page');
const colour = page === 'colour';
const tools = page !== null && !colour;
const start = page === 'tools' ? undefined : (page ?? undefined);

<template>
  {{pageTitle "Canon"}}
  {{#if colour}}
    <ColourPage />
  {{else if tools}}
    <Tools @start={{start}} />
  {{else}}
    <Gallery />
  {{/if}}
  <CanonToast />
</template>
