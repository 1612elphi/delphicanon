import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import CanonDecimalField from '#src/components/canon-decimal-field.gts';
import CanonDualList, {
  type CanonDualItem,
} from '#src/components/canon-dual-list.gts';
import CanonFigure from '#src/components/canon-figure.gts';
import CanonFileCell from '#src/components/canon-file-cell.gts';
import CanonFromTo from '#src/components/canon-from-to.gts';
import CanonGrid from '#src/components/canon-grid.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonLoader from '#src/components/canon-loader.gts';
import CanonMenuCell from '#src/components/canon-menu-cell.gts';
import CanonNumberField from '#src/components/canon-number-field.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonSlider from '#src/components/canon-slider.gts';
import CanonStatus from '#src/components/canon-status.gts';
import CanonSwitch from '#src/components/canon-switch.gts';
import CanonTextArea from '#src/components/canon-text-area.gts';
import CanonTextCell from '#src/components/canon-text-cell.gts';

import './controls.css';

export const pane = 'sidebar';
export const order = 40;

// ∑CG: gallery, a status shown as a padded row of its own
//   spec: example warning status text for the status-as-row variant; three to five words, sentence case, no period
//   sample: "Status as a row"
const statusRowText = '∑CG';

const switches = ['Images', 'Files', 'Sound'];
const longestSwitch = 'Images';
const whole = (value: number) => String(Math.round(value));
const rates = ['23.976', '24', '25'];

export default class Controls extends Component {
  @tracked number = 200;
  @tracked seconds = 1.5;
  @tracked factor = 1;
  @tracked hidden: CanonDualItem[] = [
    { id: 'b', name: 'Beta', caption: 'two' },
    { id: 'd', name: 'Delta', caption: 'four' },
  ];
  @tracked shown: CanonDualItem[] = [
    { id: 'a', name: 'Alpha', caption: 'one' },
    { id: 'c', name: 'Gamma', caption: 'three' },
  ];

  get figure() {
    return String(this.number);
  }

  setNumber = (value: number) => (this.number = value);
  setSeconds = (value: number) => (this.seconds = value);
  setFactor = (value: number) => (this.factor = value);

  moveRight = (id: string) => {
    const item = this.hidden.find((i) => i.id === id);
    if (!item) return;
    this.hidden = this.hidden.filter((i) => i !== item);
    this.shown = [...this.shown, item];
  };

  moveLeft = (id: string) => {
    const item = this.shown.find((i) => i.id === id);
    if (!item) return;
    this.shown = this.shown.filter((i) => i !== item);
    this.hidden = [...this.hidden, item];
  };

  reorder = (id: string, delta: -1 | 1) => {
    const index = this.shown.findIndex((i) => i.id === id);
    const other = index + delta;
    if (index < 0 || other < 0 || other >= this.shown.length) return;
    const next = [...this.shown];
    [next[index], next[other]] = [next[other]!, next[index]!];
    this.shown = next;
  };

  <template>
    <CanonRows @framed={{true}}>
      <CanonHeading @text="Components" />
      <CanonRow @title="Switch" as |titleId|>
        <CanonSwitch @on={{true}} aria-labelledby={{titleId}} />
      </CanonRow>
      <CanonRow @title="Number" @form="flush" as |titleId|>
        <CanonNumberField
          @value={{this.number}}
          @max={{5000}}
          @step={{50}}
          @unit="items"
          @labelledBy={{titleId}}
          @onChange={{this.setNumber}}
        />
      </CanonRow>
      <CanonRow @title="Figure" @detail="Follows Number">
        <CanonFigure @text={{this.figure}} @unit="px" @size={{28}} />
      </CanonRow>
      <CanonRow @title="Slider" @form="flush" as |titleId|>
        <CanonSlider @value={{0.65}} @labelledBy={{titleId}} />
      </CanonRow>
      <CanonRow @title="Stepped slider" @form="flush" as |titleId|>
        <CanonSlider
          @value={{80}}
          @min={{1}}
          @max={{100}}
          @step={{1}}
          @readout={{whole}}
          @labelledBy={{titleId}}
        />
      </CanonRow>
      <CanonRow @title="Text" @form="flush" as |titleId|>
        <CanonTextCell @placeholder="Trigger" aria-labelledby={{titleId}} />
      </CanonRow>
      <CanonRow @title="File" @form="flush" as |titleId|>
        <CanonFileCell @labelledBy={{titleId}} />
      </CanonRow>
      <CanonRow @title="Image" @form="flush" as |titleId|>
        <CanonFileCell @accept="image/*" @labelledBy={{titleId}} />
      </CanonRow>
      <CanonGrid>
        {{#each switches as |title index|}}
          <CanonRow @title={{title}} @sizingTitle={{longestSwitch}} as |id|>
            <CanonSwitch @on={{isEven index}} aria-labelledby={{id}} />
          </CanonRow>
        {{/each}}
      </CanonGrid>
      <CanonRow @title="Decimal" @form="flush" as |titleId|>
        <CanonDecimalField
          @value={{this.seconds}}
          @labelledBy={{titleId}}
          @onChange={{this.setSeconds}}
        />
      </CanonRow>
      <CanonRow @title="Signed, six places" @form="flush" as |titleId|>
        <CanonDecimalField
          @value={{this.factor}}
          @unit="×"
          @step={{0.001}}
          @decimals={{6}}
          @signed={{true}}
          @labelledBy={{titleId}}
          @onChange={{this.setFactor}}
        />
      </CanonRow>
      <CanonTextArea
        @placeholder="Text area"
        @height={{120}}
        aria-label="Text area"
      />
      <CanonRow @title="Menu" @form="flush" as |titleId|>
        <CanonMenuCell
          @items={{rates}}
          @selected={{0}}
          @labelledBy={{titleId}}
        />
      </CanonRow>
      <CanonFromTo @items={{rates}} @from={{0}} @to={{2}} />
      <CanonRow @title="Status">
        <div class="gallery-inline">
          <CanonStatus @text="Granted" @tone="ok" />
          <CanonStatus @text="Not granted" @tone="warn" />
          <CanonStatus @text="Stopped" @tone="muted" />
        </div>
      </CanonRow>
      <CanonStatus @text={{statusRowText}} @tone="warn" @row={{true}} />
      <CanonRow @title="Loader">
        <div class="gallery-inline gallery-loaders">
          <CanonLoader />
          <CanonLoader @mode="comet" @reverse={{true}} />
          <CanonLoader @mode="dot" />
          <CanonLoader @mode="twin" />
          <CanonLoader @mode="thinking" />
          <CanonLoader @cell={{4}} @gap={{1}} />
        </div>
      </CanonRow>
      <CanonRow @title="Dual list" @form="stacked">
        <CanonDualList
          @left={{this.hidden}}
          @right={{this.shown}}
          @leftTitle="Hidden"
          @rightTitle="Shown"
          @listHeight={{140}}
          @onMoveRight={{this.moveRight}}
          @onMoveLeft={{this.moveLeft}}
          @onReorder={{this.reorder}}
        />
      </CanonRow>
    </CanonRows>
  </template>
}

function isEven(index: number) {
  return index % 2 === 0;
}
