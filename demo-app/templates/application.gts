import { pageTitle } from 'ember-page-title';
import CanonToast from '#src/components/canon-toast.gts';
import Gallery from '../components/gallery.gts';

<template>
  {{pageTitle "Canon"}}
  <Gallery />
  <CanonToast />
</template>
