import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import '../styles/tokens.css';
import './canon-page.css';
import './canon-split.css';

export interface CanonSplitSignature {
  Args: {
    /** Never splits: the sections stack at every width, sidebar first. */
    oneColumn?: boolean;
    /** Sidebar width in px beside the main pane, at most 40 % of the split. Default 340. */
    sidebarWidth?: number;
    /** In one column the banner stays at the top and the page scrolls under it. */
    bannerSticks?: boolean;
    /** In one column the main sections come before the sidebar's. */
    mainLeadsStacked?: boolean;
    /** Side by side the panes are equal; a sidebar of one canvas fills its pane. */
    halves?: boolean;
    /** In one column the picture shrinks as the page scrolls, down to this band height in px. */
    collapsesTo?: number;
    /** Beside or above a crease, a halves picture runs into the crease band up to the rule. */
    pictureMeetsCrease?: boolean;
    footerHidden?: boolean;
  };
  Blocks: {
    sidebar: [];
    main: [];
    /** A CanonCanvas across every column, above the panes. */
    banner: [];
    /** A framed strip floating over the bottom of the main pane. */
    footer: [];
  };
  Element: HTMLDivElement;
}

/** Share of the height a collapsing picture takes before it shrinks. */
export const collapseLimit = 0.6;

function naturalHeight(canvas: HTMLElement, width: number): number {
  const fixed = Number(canvas.dataset['canonHeight']);
  if (fixed) return fixed;
  const aspect = Number(canvas.dataset['canonAspect']) || 1;
  const frame = parseFloat(
    getComputedStyle(canvas).getPropertyValue('--canon-frame'),
  );
  return width / aspect + (frame || 0) * 2;
}

const collapse = modifier(
  (split: HTMLElement, [collapsesTo]: [number | undefined]) => {
    if (collapsesTo === undefined) return;
    const body = split.querySelector<HTMLElement>(':scope > .canon-split-body');
    if (!body) return;
    const update = () => {
      const stacked =
        getComputedStyle(body)
          .getPropertyValue('--canon-split-layout')
          .trim() !== 'wide';
      const picture = split.querySelector<HTMLElement>(
        ':scope > .canon-split-body > .canon-split-banner .canon-canvas, .canon-split--halves > .canon-split-body > .canon-split-sidebar > .canon-canvas:only-child',
      );
      split.toggleAttribute('data-collapsing', stacked && !!picture);
      if (!stacked || !picture) return;
      const full = Math.min(
        naturalHeight(picture, split.clientWidth),
        split.clientHeight * collapseLimit,
      );
      // stretches when pulled down
      const band = Math.max(Math.min(collapsesTo, full), full - body.scrollTop);
      split.style.setProperty('--canon-split-full', `${full}px`);
      split.style.setProperty('--canon-split-band', `${band}px`);
    };
    update();
    body.addEventListener('scroll', update, { passive: true });
    const size = new ResizeObserver(update);
    size.observe(split);
    return () => {
      body.removeEventListener('scroll', update);
      size.disconnect();
    };
  },
);

/**
 * Sidebar beside a main pane. Wide: a fixed sidebar on the leading side.
 * Narrower than 640 px or portrait: one column, sidebar first. On a
 * dual-screen device the panes meet at the crease. Sections that are a
 * CanonCanvas span their column; the rest keep the panel padding. The split
 * fills its parent's height.
 */
export default class CanonSplit extends Component<CanonSplitSignature> {
  get style() {
    const width = this.args.sidebarWidth;
    return width === undefined
      ? undefined
      : htmlSafe(`--canon-split-sidebar: ${width}px`);
  }

  <template>
    <div
      class="canon-split
        {{if @halves 'canon-split--halves'}}
        {{if @bannerSticks 'canon-split--sticks'}}
        {{if @mainLeadsStacked 'canon-split--main-leads'}}
        {{if @pictureMeetsCrease 'canon-split--meets-crease'}}
        {{if @oneColumn 'canon-split--one-column'}}"
      style={{this.style}}
      {{collapse @collapsesTo}}
      ...attributes
    >
      <div class="canon-split-body">
        {{#if (has-block "banner")}}
          <div class="canon-split-banner">{{yield to="banner"}}</div>
        {{/if}}
        {{#if (has-block "sidebar")}}
          <div class="canon-split-pane canon-split-sidebar canon-page">
            {{yield to="sidebar"}}
          </div>
        {{/if}}
        <div class="canon-split-rule"></div>
        <div class="canon-split-pane canon-split-main canon-page">
          {{yield to="main"}}
          {{#if (has-block "footer")}}
            {{#unless @footerHidden}}
              <div class="canon-split-footer">{{yield to="footer"}}</div>
            {{/unless}}
          {{/if}}
        </div>
      </div>
    </div>
  </template>
}
