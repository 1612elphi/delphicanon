<script lang="ts">
/** The pointer may cross the gap onto the hint in this many ms before it hides. */
export const tooltipGraceMs = 100;

function describe(element: Element, id: string, on: boolean) {
	const ids = (element.getAttribute('aria-describedby') ?? '')
		.split(/\s+/)
		.filter((other) => other && other !== id);
	if (on) ids.push(id);
	if (ids.length) element.setAttribute('aria-describedby', ids.join(' '));
	else element.removeAttribute('aria-describedby');
}
</script>

<script setup lang="ts">
import { shallowRef, useId, useTemplateRef, watch } from 'vue';
import {
	attach,
	hide,
	isOpen,
	type CanonPlacement,
} from '@canon/lib/popover.ts';
import { elementOf, type CanonTriggerRef } from '../lib/trigger.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-popover.css';
import '@canon/components/canon-tooltip.css';

defineOptions({ inheritAttrs: false });

const props = defineProps<{
	text: string;
	/** Default top. */
	placement?: CanonPlacement;
}>();

defineSlots<{
	/** Bind `trigger` as the ref of the element the hint describes. */
	default?: (props: { trigger: CanonTriggerRef }) => unknown;
}>();

const id = `${useId()}-tooltip`;
const tipRef = useTemplateRef<HTMLElement>('tip');
const anchor = shallowRef<HTMLElement | null>(null);

const trigger: CanonTriggerRef = (target) => {
	anchor.value = elementOf(target);
};

watch(
	[anchor, tipRef, () => props.placement],
	([element, tip], _, onCleanup) => {
		if (!element || !tip) return;
		const detach = attach(tip, element, {
			placement: props.placement ?? 'top',
		});
		describe(element, id, true);
		let leaving: number | undefined;

		const show = () => {
			window.clearTimeout(leaving);
			if (!isOpen(tip)) tip.showPopover();
		};
		const hideNow = () => {
			window.clearTimeout(leaving);
			hide(tip);
		};
		const hideSoon = () => {
			window.clearTimeout(leaving);
			leaving = window.setTimeout(
				() => hide(tip),
				tooltipGraceMs,
			);
		};
		const enter = (event: PointerEvent) => {
			if (event.pointerType !== 'touch') show();
		};
		// a click focuses the trigger without :focus-visible, and should not bring the hint back
		const focus = () => {
			if (element.matches(':focus-visible')) show();
		};
		const escape = (event: KeyboardEvent) => {
			if (event.key === 'Escape' && isOpen(tip)) hideNow();
		};

		const listeners = [
			[element, 'pointerenter', enter],
			[element, 'pointerleave', hideSoon],
			[element, 'pointerdown', hideNow],
			[element, 'focusin', focus],
			[element, 'focusout', hideNow],
			[tip, 'pointerenter', show],
			[tip, 'pointerleave', hideSoon],
			[document, 'keydown', escape],
		] as const;
		for (const [target, type, listener] of listeners)
			target.addEventListener(
				type,
				listener as EventListener,
			);
		onCleanup(() => {
			window.clearTimeout(leaving);
			for (const [target, type, listener] of listeners)
				target.removeEventListener(
					type,
					listener as EventListener,
				);
			describe(element, id, false);
			detach();
		});
	},
	{ flush: 'post' },
);
</script>

<!--
  A hint shown while the pointer is over the trigger or keyboard focus is
  on it. Escape and a press hide it.
-->
<template>
	<slot :trigger="trigger" />
	<div
		:id="id"
		ref="tip"
		class="canon-popover canon-tooltip"
		popover="manual"
		role="tooltip"
		v-bind="$attrs"
	>
		{{ text }}
	</div>
</template>
