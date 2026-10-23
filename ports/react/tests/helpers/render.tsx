import { act, type ReactNode } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { afterEach } from 'vitest';

(
	globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }
).IS_REACT_ACT_ENVIRONMENT = true;

const mounted: { root: Root; container: HTMLElement }[] = [];

afterEach(() => {
	for (const { root, container } of mounted.splice(0)) {
		act(() => root.unmount());
		container.remove();
	}
});

export interface Rendered {
	container: HTMLElement;
	rerender: (ui: ReactNode) => Promise<void>;
	unmount: () => void;
}

/** Mounts `ui` in a fresh container in the document; unmounted after each test. */
export async function render(ui: ReactNode): Promise<Rendered> {
	const container = document.createElement('div');
	document.body.append(container);
	const root = createRoot(container);
	mounted.push({ root, container });
	await act(async () => root.render(ui));
	return {
		container,
		rerender: (next) => act(async () => root.render(next)),
		unmount: () => act(() => root.unmount()),
	};
}

type Target = string | Element;

/** The element for a selector, or throws. */
export function find<T extends Element = HTMLElement>(target: Target): T {
	const element =
		typeof target === 'string'
			? document.querySelector(target)
			: target;
	if (!element) throw new Error(`no element matches ${String(target)}`);
	return element as T;
}

export function findAll<T extends Element = HTMLElement>(
	selector: string,
): T[] {
	return [...document.querySelectorAll<T>(selector)];
}

/** Runs `fn` inside act and lets effects, timers of 0 ms and promises settle. */
export async function settle(fn?: () => unknown): Promise<void> {
	await act(async () => {
		await fn?.();
		await new Promise((resolve) => setTimeout(resolve, 0));
	});
}

export const wait = (ms: number) =>
	act(() => new Promise<void>((resolve) => setTimeout(resolve, ms)));

/** A click, as `@ember/test-helpers` click: pointer and mouse events, then click. */
export function click(target: Target): Promise<void> {
	const element = find(target);
	return settle(() => {
		const init = { bubbles: true, cancelable: true, button: 0 };
		element.dispatchEvent(new PointerEvent('pointerdown', init));
		element.dispatchEvent(new MouseEvent('mousedown', init));
		if (element instanceof HTMLElement) element.focus();
		element.dispatchEvent(new PointerEvent('pointerup', init));
		element.dispatchEvent(new MouseEvent('mouseup', init));
		element.dispatchEvent(new MouseEvent('click', init));
	});
}

const constructors: Record<
	string,
	new (type: string, init?: Record<string, unknown>) => Event
> = {
	pointerdown: PointerEvent,
	pointermove: PointerEvent,
	pointerup: PointerEvent,
	pointercancel: PointerEvent,
	pointerleave: PointerEvent,
	keydown: KeyboardEvent,
	keyup: KeyboardEvent,
	wheel: WheelEvent,
	focus: FocusEvent,
	blur: FocusEvent,
	focusin: FocusEvent,
	focusout: FocusEvent,
	input: InputEvent,
	contextmenu: MouseEvent,
	mousedown: MouseEvent,
	mouseup: MouseEvent,
	click: MouseEvent,
	dblclick: MouseEvent,
};

/** Dispatches a bubbling event of the matching class, as `triggerEvent`. */
export function trigger(
	target: Target,
	type: string,
	init: Record<string, unknown> = {},
): Promise<void> {
	const element = find(target);
	const Constructor = constructors[type] ?? Event;
	return settle(() =>
		element.dispatchEvent(
			new Constructor(type, {
				bubbles: true,
				cancelable: true,
				...init,
			}),
		),
	);
}

/** A keydown (and keyup) with `key`, as `triggerKeyEvent`. */
export async function key(
	target: Target,
	keyName: string,
	init: KeyboardEventInit = {},
): Promise<void> {
	await trigger(target, 'keydown', { key: keyName, ...init });
	await trigger(target, 'keyup', { key: keyName, ...init });
}

const valueSetters = {
	input: Object.getOwnPropertyDescriptor(
		HTMLInputElement.prototype,
		'value',
	)!.set!,
	textarea: Object.getOwnPropertyDescriptor(
		HTMLTextAreaElement.prototype,
		'value',
	)!.set!,
	select: Object.getOwnPropertyDescriptor(
		HTMLSelectElement.prototype,
		'value',
	)!.set!,
};

/** Sets a field's value the way React notices and fires input, as `fillIn`. */
export function fillIn(target: Target, value: string): Promise<void> {
	const element = find<HTMLInputElement>(target);
	const tag = element.tagName.toLowerCase() as keyof typeof valueSetters;
	return settle(() => {
		element.focus();
		valueSetters[tag].call(element, value);
		element.dispatchEvent(
			new InputEvent('input', { bubbles: true }),
		);
		element.dispatchEvent(new Event('change', { bubbles: true }));
	});
}

/** Sets a select's value and fires change, as `select`. */
export const select = fillIn;

export function focus(target: Target): Promise<void> {
	return settle(() => find(target).focus());
}

export function blur(target: Target): Promise<void> {
	return settle(() => find(target).blur());
}

/** Polls `check` every frame until it holds, as `waitUntil`; fails after `ms`. */
export async function waitUntil(
	check: () => boolean,
	ms = 1000,
): Promise<void> {
	const end = performance.now() + ms;
	while (!check()) {
		if (performance.now() > end)
			throw new Error('waitUntil timed out');
		await settle(
			() =>
				new Promise((resolve) =>
					requestAnimationFrame(resolve),
				),
		);
	}
}
