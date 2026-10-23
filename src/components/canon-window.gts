import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';
import '../styles/tokens.css';
import './canon-window.css';

export interface CanonWindowSignature {
	Args: {
		title?: string;
		/** Any of the three shows all three controls; one without a callback is disabled. */
		onClose?: () => void;
		onMinimise?: () => void;
		onZoom?: () => void;
		/** Draws the 2 px tool frame around the window. */
		framed?: boolean;
	};
	Blocks: {
		/** Trailing controls in the title bar. */
		toolbar: [];
		/** A strip under the title bar. */
		menubar: [];
		/** A CanonSidebar; it collapses to its rail when the body is narrower than 640 px. */
		sidebar: [];
		/** The detail: a CanonPage or CanonSplit fills it. */
		main: [];
	};
	Element: HTMLElement;
}

/**
 * Desktop-style window chrome (MainWindow): a title bar, an optional menu
 * bar, then the sidebar beside the detail. Fills its container.
 */
export default class CanonWindow extends Component<CanonWindowSignature> {
	titleId = `${guidFor(this)}-title`;

	get labelledBy() {
		return this.args.title ? this.titleId : undefined;
	}

	get controls() {
		const { onClose, onMinimise, onZoom } = this.args;
		return (
			onClose !== undefined ||
			onMinimise !== undefined ||
			onZoom !== undefined
		);
	}

	close = () => this.args.onClose?.();
	minimise = () => this.args.onMinimise?.();
	zoom = () => this.args.onZoom?.();

	<template>
		<section
			class="canon-window
				{{if @framed 'canon-window--framed'}}"
			aria-labelledby={{this.labelledBy}}
			...attributes
		>
			<header class="canon-window-bar">
				{{#if this.controls}}
					<div class="canon-window-controls">
						<button
							type="button"
							class="canon-window-control canon-window-control--close"
							aria-label="Close"
							disabled={{if
								@onClose
								false
								true
							}}
							{{on
								"click"
								this.close
							}}
						></button>
						<button
							type="button"
							class="canon-window-control canon-window-control--minimise"
							aria-label="Minimise"
							disabled={{if
								@onMinimise
								false
								true
							}}
							{{on
								"click"
								this.minimise
							}}
						></button>
						<button
							type="button"
							class="canon-window-control canon-window-control--zoom"
							aria-label="Zoom"
							disabled={{if
								@onZoom
								false
								true
							}}
							{{on "click" this.zoom}}
						></button>
					</div>
				{{/if}}
				<div
					class="canon-window-title"
					id={{this.titleId}}
				>{{@title}}</div>
				{{#if (has-block "toolbar")}}
					<div
						class="canon-window-toolbar"
					>{{yield to="toolbar"}}</div>
				{{/if}}
			</header>
			{{#if (has-block "menubar")}}
				<div class="canon-window-menubar">{{yield
						to="menubar"
					}}</div>
			{{/if}}
			<div class="canon-window-body">
				{{yield to="sidebar"}}
				<div class="canon-window-main">{{yield
						to="main"
					}}</div>
			</div>
		</section>
	</template>
}
