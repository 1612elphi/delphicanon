import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import type { ComponentLike } from '@glint/template';
import '../styles/tokens.css';
import './canon-row.css';

export type CanonRowForm = 'plain' | 'flush' | 'stacked';

export interface CanonRowSignature {
  Args: {
    title: string;
    detail?: string;
    /** Shown before the title in a plain row. */
    icon?: ComponentLike;
    /**
     * plain: the control keeps air around it. flush: the control meets the
     * row's top, bottom and trailing edge behind a hairline. stacked: the
     * control spans the row below the label.
     */
    form?: CanonRowForm;
    /** Longest title among sibling rows, so a grid of rows stacks as one. */
    sizingTitle?: string;
  };
  /** The control; yields the title's id for aria-labelledby. */
  Blocks: { default: [titleId: string] };
  Element: HTMLDivElement;
}

/**
 * Label beside a control. A row too narrow for both puts the control below
 * the label.
 */
export default class CanonRow extends Component<CanonRowSignature> {
  titleId = `${guidFor(this)}-title`;

  get form(): CanonRowForm {
    return this.args.form ?? 'plain';
  }

  get showsIcon() {
    return this.args.icon !== undefined && this.form === 'plain';
  }

  <template>
    <div class="canon-row canon-row--{{this.form}}" ...attributes>
      <div class="canon-row-label">
        {{#if this.showsIcon}}
          <span class="canon-row-icon" aria-hidden="true">
            {{#let @icon as |Icon|}}{{#if Icon}}<Icon />{{/if}}{{/let}}
          </span>
        {{/if}}
        <div class="canon-row-text">
          <span class="canon-row-title" id={{this.titleId}}>{{@title}}</span>
          {{#if @detail}}
            <span class="canon-row-detail">{{@detail}}</span>
          {{/if}}
          {{#if @sizingTitle}}
            <span
              class="canon-row-title canon-row-sizer"
              aria-hidden="true"
            >{{@sizingTitle}}</span>
          {{/if}}
        </div>
      </div>
      {{#if (has-block)}}
        <div class="canon-row-control">{{yield this.titleId}}</div>
      {{/if}}
    </div>
  </template>
}
