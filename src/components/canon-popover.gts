import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { hash } from '@ember/helper';
import { modifier } from 'ember-modifier';
import type { ModifierLike } from '@glint/template';
import { attach, hide, panelFor, type CanonPlacement } from '../lib/popover.ts';
import '../styles/tokens.css';
import './canon-popover.css';

export type CanonPopoverTrigger = ModifierLike<{ Element: HTMLButtonElement }>;

export interface CanonPopoverSignature {
	Args: {
		/** Default bottom-start. The panel flips to the other side when it does not fit. */
		placement?: CanonPlacement;
	};
	Blocks: {
		/** Put `trigger` on the button that opens the panel. */
		trigger: [{ trigger: CanonPopoverTrigger; close: () => void }];
		content: [{ close: () => void }];
	};
	Element: HTMLDivElement;
}

/**
 * A panel anchored to the consumer's button. The button toggles it; a
 * click outside or Escape closes it, and focus inside goes back to the
 * button. Give the panel a role and a label (`role="dialog"
 * aria-label="…"`) and `autofocus` on what should take focus.
 */
export default class CanonPopover extends Component<CanonPopoverSignature> {
	id = `${guidFor(this)}-popover`;
	#panel?: HTMLElement;

	trigger = modifier((button: HTMLButtonElement) => {
		const panel = panelFor(button, this.id);
		this.#panel = panel;
		return attach(panel, button, {
			placement: this.args.placement ?? 'bottom-start',
			invokes: true,
		});
	});

	close = () => {
		if (this.#panel) hide(this.#panel);
	};

	<template>
		{{yield
			(hash trigger=this.trigger close=this.close)
			to="trigger"
		}}
		<div
			id={{this.id}}
			class="canon-popover"
			popover="auto"
			...attributes
		>
			{{yield (hash close=this.close) to="content"}}
		</div>
	</template>
}
