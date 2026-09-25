import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { htmlSafe } from '@ember/template';
import CanonButton from '#src/components/canon-button.gts';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonGrid from '#src/components/canon-grid.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonMathField, {
  CanonMathFieldHandle,
} from '#src/components/canon-math-field.gts';
import CanonMathKey from '#src/components/canon-math-key.gts';
import CanonMathKeypad from '#src/components/canon-math-keypad.gts';
import CanonMathView from '#src/components/canon-math-view.gts';
import CanonRows from '#src/components/canon-rows.gts';
import type { Key } from '#src/lib/math/expression.ts';

export const pane = 'main';
export const order = 30;

const inserts: Key[] = [
  { kind: 'fraction' },
  { kind: 'power' },
  { kind: 'root' },
  { kind: 'symbol', symbol: '×' },
];
const morphs = ['(x+1)^2', 'x^2+2*x+1', '(x+1)*(x+1)'];
const views = [
  'sqrt(x^2+1)/(2*x)',
  'defint(sin(x)^2,0,pi,x)',
  'sum(k^2,k,1,n)',
];
const viewRow = htmlSafe(
  'display: flex; flex-wrap: wrap; gap: 24px; align-items: center; justify-content: space-around; padding: 16px; background: var(--canon-card)',
);
const fill = htmlSafe('block-size: 100%');

export default class MathGroup extends Component {
  handle = new CanonMathFieldHandle();
  @tracked morph = 0;

  get morphText() {
    return morphs[this.morph % morphs.length];
  }

  next = () => (this.morph += 1);
  insert = (key: Key) => this.handle.edit([key]);

  <template>
    <CanonRows @framed={{true}}>
      <CanonHeading @text="Maths input" />
      <CanonMathField
        @text="(x+1)^2/2"
        @placeholder="x^2 - 4"
        @handle={{this.handle}}
      />
      <CanonMathField @variable="t" @placeholder="sin(t)" />
      <CanonGrid @columns={{4}}>
        {{#each inserts as |key|}}
          <CanonMathKey @key={{key}} @onClick={{fn this.insert key}} />
        {{/each}}
      </CanonGrid>
      <CanonHeading @text="Maths view" />
      <div style={{viewRow}}>
        {{#each views as |text|}}
          <CanonMathView @text={{text}} @size={{22}} />
        {{/each}}
        <CanonMathView @text="b*c^(-1)+(1/2)*x^(-1/2)" @presents={{true}} />
      </div>
    </CanonRows>
    <CanonCanvas @height={{140}}>
      <CanonMathView
        @text={{this.morphText}}
        @size={{34}}
        @morphs={{true}}
        style={{fill}}
      />
    </CanonCanvas>
    <CanonRows @framed={{true}}>
      <CanonButton @text="Morph" @onClick={{this.next}} />
      <CanonHeading @text="Maths keypad" />
      <CanonMathKeypad @variable="t" />
    </CanonRows>
  </template>
}
