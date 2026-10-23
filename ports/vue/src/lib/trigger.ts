import type { ComponentPublicInstance } from 'vue';

/**
 * A function template ref, the port of a yielded Ember modifier: bind it
 * with `:ref="trigger"` on an element or a single-root component.
 */
export type CanonTriggerRef = (
	target: Element | ComponentPublicInstance | null,
) => void;

/** The element a function ref received: the element itself, or a component's root. */
export function elementOf(
	target: Element | ComponentPublicInstance | null,
): HTMLElement | null {
	const element: unknown =
		target && !(target instanceof Element) ? target.$el : target;
	return element instanceof HTMLElement ? element : null;
}
