import type { TOC } from '@ember/component/template-only';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import CanonBar from '#src/components/canon-bar.gts';
import CanonFigure from '#src/components/canon-figure.gts';
import CanonLoader from '#src/components/canon-loader.gts';
import { springEasing } from '#src/lib/motion.ts';
import { formatBytes, savingsFigure } from './compress.ts';

// the iOS bar spring: 0.6 s, damping 0.7
const springStyle = htmlSafe(`--ic-spring-easing: ${springEasing(0.7)}`);

interface BarSignature {
  Args: {
    label: string;
    bytes: number;
    share: number;
    fill: string;
    /** Label colour inside the fill. */
    ink: string;
  };
}

/** The label sits inside the fill when it fits with 20 px to spare, else after it. */
const place = modifier((bar: HTMLElement, [share]: [number, string]) => {
  const label = bar.querySelector<HTMLElement>('.ic-bar-label')!;
  const update = () =>
    bar.toggleAttribute(
      'data-inside',
      bar.clientWidth * share >= label.offsetWidth + 20,
    );
  update();
  const observer = new ResizeObserver(update);
  observer.observe(bar);
  return () => observer.disconnect();
});

const barStyle = (share: number, ink: string) =>
  htmlSafe(`--ic-share: ${Math.min(Math.max(share, 0), 1)}; --ic-ink: ${ink}`);

const labelOf = (label: string, bytes: number) =>
  bytes > 0 ? `${label}  ${formatBytes(bytes)}` : label;

const Bar: TOC<BarSignature> = <template>
  <div
    class="ic-bar"
    style={{barStyle @share @ink}}
    {{place @share (labelOf @label @bytes)}}
  >
    <CanonBar @share={{@share}} @fill={{@fill}} @track="transparent" />
    <span class="ic-bar-label">{{labelOf @label @bytes}}</span>
  </div>
</template>;

interface ScaleSignature {
  Args: {
    before: number;
    after: number;
    /** The result bar's label. */
    format: string;
    working: boolean;
  };
}

const known = (before: number, after: number) => before > 0 && after > 0;
const grew = (before: number, after: number) => after > before;
const share = (before: number, after: number) =>
  known(before, after) ? Math.min(1, after / before) : 0;
const colour = (before: number, after: number) =>
  grew(before, after) ? 'var(--canon-destructive)' : 'var(--canon-primary)';
const figure = (before: number, after: number) =>
  known(before, after) ? savingsFigure(before, after) : '—';
const unit = (before: number, after: number) =>
  known(before, after) ? '%' : undefined;

/** Two bars to one scale, the original's bytes over the result's, with the saving as a figure. */
const Scale: TOC<ScaleSignature> = <template>
  <div class="ic-scale" style={{springStyle}}>
    <div class="ic-scale-top">
      {{#if @working}}
        <CanonLoader class="ic-scale-loader" @cell={{5}} @gap={{1}} />
      {{/if}}
      <CanonFigure
        class="ic-scale-figure"
        @text={{figure @before @after}}
        @unit={{unit @before @after}}
        @colour={{colour @before @after}}
      />
    </div>
    <Bar
      @label="Original"
      @bytes={{@before}}
      @share={{1}}
      @fill="var(--canon-muted)"
      @ink="var(--canon-foreground)"
    />
    <Bar
      @label={{@format}}
      @bytes={{if (known @before @after) @after 0}}
      @share={{share @before @after}}
      @fill={{colour @before @after}}
      @ink="var(--canon-primary-foreground)"
    />
  </div>
</template>;

export default Scale;
