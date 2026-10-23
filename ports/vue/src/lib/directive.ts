import type { Directive } from 'vue';

/**
 * A directive from a setup function that runs once per element and returns
 * its teardown; `value()` reads the latest binding value.
 */
export function elementDirective<V>(
	setup: (element: HTMLElement, value: () => V) => () => void,
): Directive<HTMLElement, V> {
	const live = new WeakMap<HTMLElement, { value: V; stop: () => void }>();
	return {
		mounted(element, binding) {
			const entry = { value: binding.value, stop: () => {} };
			live.set(element, entry);
			entry.stop = setup(element, () => entry.value);
		},
		updated(element, binding) {
			const entry = live.get(element);
			if (entry) entry.value = binding.value;
		},
		beforeUnmount(element) {
			live.get(element)?.stop();
			live.delete(element);
		},
	};
}
