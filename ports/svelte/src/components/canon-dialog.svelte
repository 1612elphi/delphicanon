<script lang="ts" module>
	import type { Snippet } from 'svelte';
	import type { HTMLDialogAttributes } from 'svelte/elements';

	/** Closes with the motion out; `onClose` then gets `returnValue`. */
	export type CanonDialogClose = (returnValue?: string) => void;

	export interface CanonDialogProps extends Omit<
		HTMLDialogAttributes,
		'open' | 'title' | 'children' | 'onclose'
	> {
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
		/** Above the message, under the heading: a search field, a row. */
		header?: Snippet<[close: CanonDialogClose]>;
		/** Rows, separated by hairlines; scrolls when the dialog is full. */
		children?: Snippet<[close: CanonDialogClose]>;
		/** Buttons, laid in a CanonGrid. */
		footer?: Snippet<[close: CanonDialogClose]>;
		/** Keyframes of the motion in, played backwards on the way out; CanonSheet slides. */
		keyframes?: (dialog: HTMLDialogElement) => Keyframe[];
	}
</script>

<script lang="ts">
	import type { Attachment } from 'svelte/attachments';
	import CanonGrid from './canon-grid.svelte';
	import CanonHeading from './canon-heading.svelte';
	import CanonRows from './canon-rows.svelte';
	import { dialogMotion, reducedMotion } from '@canon/lib/motion.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-dialog.css';

	let {
		open,
		title,
		message,
		alert,
		dismissable = true,
		onClose,
		header,
		children,
		footer,
		keyframes = () => [
			{
				opacity: 0,
				transform: `scale(${dialogMotion.scale})`,
			},
			{ opacity: 1, transform: 'none' },
		],
		class: className,
		...rest
	}: CanonDialogProps = $props();

	const uid = $props.id();
	const titleId = `${uid}-title`;
	const messageId = `${uid}-message`;
	let element: HTMLDialogElement | undefined;
	let invoker: HTMLElement | undefined;
	let closing = false;

	function animate(
		dialog: HTMLDialogElement,
		entering: boolean,
	): Animation[] {
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
			dialog.animate(keyframes(dialog), options),
			dialog.animate([{ opacity: 0 }, { opacity: 1 }], {
				...options,
				pseudoElement: '::backdrop',
			}),
		];
	}

	const close: CanonDialogClose = (returnValue = '') => {
		const dialog = element;
		if (!dialog?.open || closing) return;
		closing = true;
		const animations = reducedMotion()
			? []
			: animate(dialog, false);
		const done = () => {
			closing = false;
			dialog.close(returnValue);
			// fill would hold next opening
			animations.forEach((animation) => animation.cancel());
		};
		Promise.all(
			animations.map((animation) => animation.finished),
		).then(done, done);
	};

	const present: Attachment<HTMLDialogElement> = (dialog) => {
		element = dialog;
		if (open && !dialog.open) {
			const active = document.activeElement;
			invoker =
				active instanceof HTMLElement
					? active
					: undefined;
			dialog.returnValue = '';
			dialog.showModal();
			if (!reducedMotion()) animate(dialog, true);
		} else if (!open && dialog.open) {
			dialog.close();
		}

		const cancel = (event: Event) => {
			event.preventDefault();
			if (dismissable) close();
		};
		// press must start outside
		let downOnBackdrop = false;
		const down = (event: PointerEvent) => {
			downOnBackdrop = event.target === dialog;
		};
		const click = (event: MouseEvent) => {
			if (!downOnBackdrop || event.target !== dialog) return;
			if (alert || !dismissable) return;
			const r = dialog.getBoundingClientRect();
			const inside =
				event.clientX >= r.left &&
				event.clientX <= r.right &&
				event.clientY >= r.top &&
				event.clientY <= r.bottom;
			if (!inside) close();
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
			close(submitter?.value ?? '');
		};
		const closed = () => {
			const focusBack = invoker;
			invoker = undefined;
			if (focusBack?.isConnected) focusBack.focus();
			onClose?.(dialog.returnValue);
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
	};
</script>

<!--
  @component
  A modal dialog: the platform's `<dialog>` with `showModal`, so the top
  layer, the focus trap, Escape and `inert` on the page are the browser's.
  Content renders while `open`; focus returns to the element that had it.
-->
<dialog
	class={['canon-dialog', alert && 'canon-dialog--alert', className]}
	role={alert ? 'alertdialog' : undefined}
	aria-labelledby={title ? titleId : undefined}
	aria-describedby={message ? messageId : undefined}
	{@attach present}
	{...rest}
>
	{#if open}
		<CanonRows framed class="canon-dialog-rows">
			{#if title}
				<CanonHeading
					text={title}
					id={titleId}
					class="canon-dialog-title"
				/>
			{/if}
			{#if header}
				<div class="canon-dialog-header">
					{@render header(close)}
				</div>
			{/if}
			{#if message}
				<p class="canon-dialog-message" id={messageId}>
					{message}
				</p>
			{/if}
			{#if children}
				<div class="canon-dialog-body">
					{@render children(close)}
				</div>
			{/if}
			{#if footer}
				<CanonGrid class="canon-dialog-footer"
					>{@render footer(close)}</CanonGrid
				>
			{/if}
		</CanonRows>
	{/if}
</dialog>
