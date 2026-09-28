import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import type { ComponentLike } from '@glint/template';
import '../styles/tokens.css';
import './canon-sidebar-row.css';

/** neutral: no state. off: disabled module. on and warning light the leading edge. */
export type CanonSidebarLight = 'neutral' | 'off' | 'on' | 'warning';

export interface CanonSidebarRowSignature {
  Args: {
    title: string;
    /** Rendered in the 44 px icon cell; the consumer supplies it. */
    icon?: ComponentLike;
    /** Default neutral. */
    light?: CanonSidebarLight;
    /** The current page: filled in primary, `aria-current="page"`. */
    selected?: boolean;
    /** Makes the row a link; without it the row is a button. */
    href?: string;
    onClick?: (event: MouseEvent) => void;
  };
  Element: HTMLAnchorElement | HTMLButtonElement;
}

/** One navigation row of a CanonSidebar: an icon cell and a title cell (SidebarRow). */
export default class CanonSidebarRow extends Component<CanonSidebarRowSignature> {
  get light(): CanonSidebarLight {
    return this.args.light ?? 'neutral';
  }

  get current() {
    return this.args.selected ? 'page' : undefined;
  }

  click = (event: MouseEvent) => this.args.onClick?.(event);

  <template>
    {{#if @href}}
      <a
        href={{@href}}
        class="canon-sidebar-row canon-sidebar-row--{{this.light}}"
        aria-current={{this.current}}
        {{on "click" this.click}}
        ...attributes
      >
        <span class="canon-sidebar-row-icon" aria-hidden="true">
          {{#if @icon}}<@icon />{{/if}}
        </span>
        <span class="canon-sidebar-row-title">{{@title}}</span>
      </a>
    {{else}}
      <button
        type="button"
        class="canon-sidebar-row canon-sidebar-row--{{this.light}}"
        aria-current={{this.current}}
        {{on "click" this.click}}
        ...attributes
      >
        <span class="canon-sidebar-row-icon" aria-hidden="true">
          {{#if @icon}}<@icon />{{/if}}
        </span>
        <span class="canon-sidebar-row-title">{{@title}}</span>
      </button>
    {{/if}}
  </template>
}
