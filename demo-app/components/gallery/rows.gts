import CanonBar from '#src/components/canon-bar.gts';
import CanonEmptyRow from '#src/components/canon-empty-row.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import Icon from '../icon.gts';
import bug from 'lucide-static/icons/bug.svg?raw';

export const pane = 'sidebar';
export const order = 10;

<template>
  <CanonRows @framed={{true}}>
    <CanonHeading @text="Rows" />
    <CanonRow @title="Plain"><CanonBar
        class="gallery-bar"
        @share={{0.65}}
      /></CanonRow>
    <CanonRow
      @title="Detail and icon"
      @icon={{component Icon svg=bug}}
      {{! ∑CG: gallery, caption under the "Detail and icon" row title }}
      {{! spec: shows what a row's detail line looks like; plain, lowercase after the first word, about 25 characters }}
      {{! sample: "Caption under the title" }}
      @detail="∑CG"
    ><CanonBar class="gallery-bar" @share={{0.3}} /></CanonRow>
    <CanonRow @title="No control" />
    <CanonEmptyRow @text="Nothing here" />
  </CanonRows>
</template>
