import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import CanonCanvas from '#src/components/canon-canvas.gts';
import GalleryArt from '../gallery-art.gts';

export const pane = 'main';
export const order = 10;

export default class CanvasGallery extends Component {
  @tracked lines = 1;

  get text() {
    return Array.from({ length: this.lines }, (_, i) => `Line ${i + 1}`);
  }

  more = () => (this.lines = (this.lines % 4) + 1);

  <template>
    <CanonCanvas @aspect={{4}}><GalleryArt
        @label="Column canvas"
      /></CanonCanvas>
    <CanonCanvas @fitting={{true}} @animated={{true}}>
      <button type="button" class="gallery-fit" {{on "click" this.more}}>
        {{#each this.text as |line|}}<span>{{line}}</span>{{/each}}
      </button>
    </CanonCanvas>
    <CanonCanvas @aspect={{4}} @boxing="unlessWide">
      <GalleryArt @label="Boxed unless wide" />
    </CanonCanvas>
  </template>
}
