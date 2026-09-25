import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import CanonColourWell from '#src/components/canon-colour-well.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonRows from '#src/components/canon-rows.gts';
import type { Rgb } from '#src/lib/colour.ts';

export const pane = 'main';
export const order = 40;

export default class ColourGallery extends Component {
  @tracked foreground: Rgb = [0.118, 0.4, 0.149];
  @tracked orange: Rgb = [1, 0.584, 0];

  setForeground = (colour: Rgb) => (this.foreground = colour);
  setOrange = (colour: Rgb) => (this.orange = colour);

  <template>
    <CanonRows @framed={{true}}>
      <CanonHeading @text="Wells" />
      <CanonColourWell
        @label="Foreground"
        @colour={{this.foreground}}
        @format="oklch"
        @onChange={{this.setForeground}}
      />
      <CanonColourWell @colour={{this.orange}} @onChange={{this.setOrange}} />
    </CanonRows>
  </template>
}
