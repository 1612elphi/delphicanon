import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { modifier } from 'ember-modifier';
import CanonGrid from './canon-grid.gts';
import CanonHeading from './canon-heading.gts';
import CanonRows from './canon-rows.gts';
import { dialogMotion, reducedMotion } from '../lib/motion.ts';
import '../styles/tokens.css';
import './canon-dialog.css';

/** Closes with the motion out; `onClose` then gets `returnValue`. */
export type CanonDialogClose = (returnValue?: string) => void;

export interface CanonDialogSignature {
	Args: {
		/** Opens with `showModal`. The owner sets it back to false in `onClose`; setting it false itself closes at once, without motion. */
		open: boolean;
		/** The heading, and the dialog's accessible name. */
		title?: string;
		/** Text under the heading, and the accessible description. */
		message?: string;
		/** role alertdialog; a click on the backdrop does not close it. */
		alert?: boolean;
		/** Escape and a click on the backdrop close it; default true. */
		dismissable?: boolean;
		/** Every close, with the return value: the argument to `close`, or the value of the button that submitted a `method="dialog"` form. */
		onClose?: (returnValue: string) => void;
	};
	Blocks: {
		/** Above the message, under the heading: a search field, a row. */
		header: [close: CanonDialogClose];
		/** Rows, separated by hairlines; scrolls when the dialog is full. */
		default: [close: CanonDialogClose];
		/** Buttons, laid in a CanonGrid. */
		footer: [close: CanonDialogClose];
	};
	Element: HTMLDialogElement;
}

/**
 * A modal dialog: the platform's `<dialog>` with `showModal`, so the top
 * layer, the focus trap, Escape and `inert` on the page are the browser's.
 * Content renders while `open`; focus returns to the element that had it.
 */
export default class CanonDialog<
	A extends CanonDialogSignature['Args'] = CanonDialogSignature['Args'],
> extends Component<Omit<CanonDialogSignature, 'Args'> & { Args: A }> {
	titleId = `${guidFor(this)}-title`;
	messageId = `${guidFor(this)}-message`;
	element?: HTMLDialogElement;
	#invoker?: HTMLElement;
	#closing = false;

	get classNames(): string {
		return this.args.alert
			? 'canon-dialog canon-dialog--alert'
			: 'canon-dialog';
	}

	get dismissable(): boolean {
		return this.args.dismissable ?? true;
	}

	/** Keyframes of the motion in; played backwards on the way out. */
	keyframes(): Keyframe[] {
		return [
			{
				opacity: 0,
				transform: `scale(${dialogMotion.scale})`,
			},
			{ opacity: 1, transform: 'none' },
		];
	}

	#animate(dialog: HTMLDialogElement, entering: boolean): Animation[] {
		const options: KeyframeAnimationOptions = entering
			? {
					duration: dialogMotion.inMs,
					easing: dialogMotion.inEasing,
				}
			: {
					duration: dialogMotion.outMs,
					easing: dialogMotion.outEasing,
					direction: 'reverse',
					fill: 'forwards',
				};
		return [
			dialog.animate(this.keyframes(), options),
			dialog.animate([{ opacity: 0 }, { opacity: 1 }], {
				...options,
				pseudoElement: '::backdrop',
			}),
		];
	}

	close: CanonDialogClose = (returnValue = '') => {
		const dialog = this.element;
		if (!dialog?.open || this.#closing) return;
		this.#closing = true;
		const animations = reducedMotion()
			? []
			: this.#animate(dialog, false);
		const done = () => {
			this.#closing = false;
			dialog.close(returnValue);
			// fill would hold next opening
			animations.forEach((animation) => animation.cancel());
		};
		Promise.all(
			animations.map((animation) => animation.finished),
		).then(done, done);
	};

	present = modifier((dialog: HTMLDialogElement, [open]: [boolean]) => {
		this.element = dialog;
		if (open && !dialog.open) {
			const active = document.activeElement;
			this.#invoker =
				active instanceof HTMLElement
					? active
					: undefined;
			dialog.returnValue = '';
			dialog.showModal();
			if (!reducedMotion()) this.#animate(dialog, true);
		} else if (!open && dialog.open) {
			dialog.close();
		}

		const cancel = (event: Event) => {
			event.preventDefault();
			if (this.dismissable) this.close();
		};
		// press must start outside
		let downOnBackdrop = false;
		const down = (event: PointerEvent) => {
			downOnBackdrop = event.target === dialog;
		};
		const click = (event: MouseEvent) => {
			if (!downOnBackdrop || event.target !== dialog) return;
			if (this.args.alert || !this.dismissable) return;
			const r = dialog.getBoundingClientRect();
			const inside =
				event.clientX >= r.left &&
				event.clientX <= r.right &&
				event.clientY >= r.top &&
				event.clientY <= r.bottom;
			if (!inside) this.close();
		};
		const submit = (event: SubmitEvent) => {
			if (
				(event.target as HTMLFormElement).method !==
				'dialog'
			)
				return;
			event.preventDefault();
			const submitter =
				event.submitter as HTMLButtonElement | null;
			this.close(submitter?.value ?? '');
		};
		const closed = () => {
			const invoker = this.#invoker;
			this.#invoker = undefined;
			if (invoker?.isConnected) invoker.focus();
			this.args.onClose?.(dialog.returnValue);
		};

		dialog.addEventListener('cancel', cancel);
		dialog.addEventListener('pointerdown', down);
		dialog.addEventListener('click', click);
		dialog.addEventListener('submit', submit);
		dialog.addEventListener('close', closed);
		return () => {
			dialog.removeEventListener('cancel', cancel);
			dialog.removeEventListener('pointerdown', down);
			dialog.removeEventListener('click', click);
			dialog.removeEventListener('submit', submit);
			dialog.removeEventListener('close', closed);
		};
	});

	<template>
		<dialog
			class={{this.classNames}}
			role={{if @alert "alertdialog"}}
			aria-labelledby={{if @title this.titleId}}
			aria-describedby={{if @message this.messageId}}
			{{this.present @open}}
			...attributes
		>
			{{#if @open}}
				<CanonRows
					@framed={{true}}
					class="canon-dialog-rows"
				>
					{{#if @title}}
						<CanonHeading
							@text={{@title}}
							id={{this.titleId}}
							class="canon-dialog-title"
						/>
					{{/if}}
					{{#if (has-block "header")}}
						<div
							class="canon-dialog-header"
						>{{yield
								this.close
								to="header"
							}}</div>
					{{/if}}
					{{#if @message}}
						<p
							class="canon-dialog-message"
							id={{this.messageId}}
						>{{@message}}</p>
					{{/if}}
					{{#if (has-block)}}
						<div
							class="canon-dialog-body"
						>{{yield this.close}}</div>
					{{/if}}
					{{#if (has-block "footer")}}
						<CanonGrid
							class="canon-dialog-footer"
						>{{yield
								this.close
								to="footer"
							}}</CanonGrid>
					{{/if}}
				</CanonRows>
			{{/if}}
		</dialog>
	</template>
}
