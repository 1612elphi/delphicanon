<script lang="ts">
/** Closes with the motion out; `onClose` then gets `returnValue`. */
export type CanonDialogClose = (returnValue?: string) => void;
</script>

<script setup lang="ts">
import { onMounted, useId, useTemplateRef, watch } from 'vue';
import { dialogMotion, reducedMotion } from '@canon/lib/motion.ts';
import CanonGrid from './canon-grid.vue';
import CanonHeading from './canon-heading.vue';
import CanonRows from './canon-rows.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-dialog.css';

const props = withDefaults(
	defineProps<{
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
		/** Keyframes of the motion in, played backwards on the way out; CanonSheet slides. Default a fade from a smaller scale. */
		keyframes?: (dialog: HTMLDialogElement) => Keyframe[];
	}>(),
	{ dismissable: undefined },
);

defineSlots<{
	/** Above the message, under the heading: a search field, a row. */
	header?: (props: { close: CanonDialogClose }) => unknown;
	/** Rows, separated by hairlines; scrolls when the dialog is full. */
	default?: (props: { close: CanonDialogClose }) => unknown;
	/** Buttons, laid in a CanonGrid. */
	footer?: (props: { close: CanonDialogClose }) => unknown;
}>();

const titleId = `${useId()}-title`;
const messageId = `${useId()}-message`;
const dialogRef = useTemplateRef<HTMLDialogElement>('dialog');
let invoker: HTMLElement | undefined;
let closing = false;
// press must start outside
let downOnBackdrop = false;

const dismissable = () => props.dismissable ?? true;

function frames(dialog: HTMLDialogElement): Keyframe[] {
	if (props.keyframes) return props.keyframes(dialog);
	return [
		{ opacity: 0, transform: `scale(${dialogMotion.scale})` },
		{ opacity: 1, transform: 'none' },
	];
}

function animate(dialog: HTMLDialogElement, entering: boolean): Animation[] {
	const options: KeyframeAnimationOptions = entering
		? { duration: dialogMotion.inMs, easing: dialogMotion.inEasing }
		: {
				duration: dialogMotion.outMs,
				easing: dialogMotion.outEasing,
				direction: 'reverse',
				fill: 'forwards',
			};
	return [
		dialog.animate(frames(dialog), options),
		dialog.animate([{ opacity: 0 }, { opacity: 1 }], {
			...options,
			pseudoElement: '::backdrop',
		}),
	];
}

const close: CanonDialogClose = (returnValue = '') => {
	const dialog = dialogRef.value;
	if (!dialog?.open || closing) return;
	closing = true;
	const animations = reducedMotion() ? [] : animate(dialog, false);
	const done = () => {
		closing = false;
		dialog.close(returnValue);
		// fill would hold next opening
		animations.forEach((animation) => animation.cancel());
	};
	Promise.all(animations.map((animation) => animation.finished)).then(
		done,
		done,
	);
};

function present() {
	const dialog = dialogRef.value;
	if (!dialog) return;
	if (props.open && !dialog.open) {
		const active = document.activeElement;
		invoker = active instanceof HTMLElement ? active : undefined;
		dialog.returnValue = '';
		dialog.showModal();
		if (!reducedMotion()) animate(dialog, true);
	} else if (!props.open && dialog.open) {
		dialog.close();
	}
}

onMounted(present);
watch(() => props.open, present, { flush: 'post' });

function cancel(event: Event) {
	event.preventDefault();
	if (dismissable()) close();
}

function down(event: PointerEvent) {
	downOnBackdrop = event.target === dialogRef.value;
}

function click(event: MouseEvent) {
	const dialog = dialogRef.value;
	if (!dialog || !downOnBackdrop || event.target !== dialog) return;
	if (props.alert || !dismissable()) return;
	const r = dialog.getBoundingClientRect();
	const inside =
		event.clientX >= r.left &&
		event.clientX <= r.right &&
		event.clientY >= r.top &&
		event.clientY <= r.bottom;
	if (!inside) close();
}

function submit(event: SubmitEvent) {
	if ((event.target as HTMLFormElement).method !== 'dialog') return;
	event.preventDefault();
	const submitter = event.submitter as HTMLButtonElement | null;
	close(submitter?.value ?? '');
}

function closed() {
	const was = invoker;
	invoker = undefined;
	if (was?.isConnected) was.focus();
	props.onClose?.(dialogRef.value?.returnValue ?? '');
}
</script>

<!--
  A modal dialog: the platform's <dialog> with showModal, so the top
  layer, the focus trap, Escape and inert on the page are the browser's.
  Content renders while open; focus returns to the element that had it.
-->
<template>
	<dialog
		ref="dialog"
		class="canon-dialog"
		:class="{ 'canon-dialog--alert': alert }"
		:role="alert ? 'alertdialog' : undefined"
		:aria-labelledby="title ? titleId : undefined"
		:aria-describedby="message ? messageId : undefined"
		@cancel="cancel"
		@pointerdown="down"
		@click="click"
		@submit="submit"
		@close="closed"
	>
		<CanonRows v-if="open" :framed="true" class="canon-dialog-rows">
			<CanonHeading
				v-if="title"
				:id="titleId"
				:text="title"
				class="canon-dialog-title"
			/>
			<div v-if="$slots.header" class="canon-dialog-header">
				<slot name="header" :close="close" />
			</div>
			<p
				v-if="message"
				:id="messageId"
				class="canon-dialog-message"
			>
				{{ message }}
			</p>
			<div v-if="$slots.default" class="canon-dialog-body">
				<slot :close="close" />
			</div>
			<CanonGrid
				v-if="$slots.footer"
				class="canon-dialog-footer"
			>
				<slot name="footer" :close="close" />
			</CanonGrid>
		</CanonRows>
	</dialog>
</template>
