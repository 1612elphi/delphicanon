import { createRawSnippet, tick } from 'svelte';
import type { CanonToastStore } from '../src/lib/toast-store.svelte.ts';

type Target = string | Element;

/** A stand-in icon. */
export const dot = createRawSnippet(() => ({
  render: () =>
    '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="6" /></svg>',
}));

export const wait = (ms: number) =>
  new Promise((resolve) => setTimeout(resolve, ms));

/** Svelte's pending updates, then one task, as Ember's settled. */
export async function settled() {
  await tick();
  await wait(0);
  await tick();
}

export function find<T extends Element = HTMLElement>(target: Target): T {
  const element =
    typeof target === 'string' ? document.querySelector(target) : target;
  if (!element) throw new Error(`no element for ${String(target)}`);
  return element as T;
}

export const findAll = <T extends Element = HTMLElement>(selector: string) => [
  ...document.querySelectorAll<T>(selector),
];

function fire(element: Element, type: string, init: object = {}) {
  const options = { bubbles: true, cancelable: true, ...init };
  const event = type.startsWith('pointer')
    ? new PointerEvent(type, { pointerId: 1, isPrimary: true, ...options })
    : type.startsWith('key')
      ? new KeyboardEvent(type, options)
      : type.startsWith('mouse') || type === 'click' || type === 'contextmenu'
        ? new MouseEvent(type, options)
        : type.startsWith('focus') || type === 'blur'
          ? new FocusEvent(type, options)
          : new Event(type, options);
  element.dispatchEvent(event);
  return event;
}

/** Ember's click: mousedown, focus, mouseup, click; throws on a disabled control. */
export async function click(target: Target, init: MouseEventInit = {}) {
  const element = find(target);
  if (element.matches(':disabled')) throw new Error('disabled');
  const options = { button: 0, buttons: 1, ...init };
  const down = fire(element, 'mousedown', options);
  if (!down.defaultPrevented) element.focus?.();
  fire(element, 'mouseup', options);
  fire(element, 'click', options);
  await settled();
}

export async function triggerEvent(
  target: Target,
  type: string,
  init: object = {},
) {
  fire(find(target), type, init);
  await settled();
}

export async function triggerKeyEvent(
  target: Target,
  type: 'keydown' | 'keyup' | 'keypress',
  key: string,
  modifiers: KeyboardEventInit = {},
) {
  fire(find(target), type, { key, ...modifiers });
  await settled();
}

export async function focus(target: Target) {
  find(target).focus();
  await settled();
}

export async function blur(target: Target) {
  find(target).blur();
  await settled();
}

/** Ember's fillIn: focus, set the value, input and change. */
export async function fillIn(target: Target, text: string) {
  const element = find<HTMLInputElement | HTMLTextAreaElement>(target);
  element.focus();
  element.value = text;
  fire(element, 'input');
  fire(element, 'change');
  await settled();
}

/** Replaces the toast store's clipboard write; returns what was written. */
export function fakeClipboard(toast: CanonToastStore): string[] {
  const written: string[] = [];
  toast.write = (text) => {
    written.push(text);
    return Promise.resolve();
  };
  return written;
}

/** Polls until `check` holds or the time runs out, as Ember's waitUntil. */
export async function waitUntil(check: () => boolean, timeout = 1000) {
  const end = performance.now() + timeout;
  while (!check()) {
    if (performance.now() > end) throw new Error('waitUntil timed out');
    await wait(10);
  }
}

export const nextFrame = () =>
  new Promise((resolve) => requestAnimationFrame(() => resolve(undefined)));

/** Ember's select: focus, set the value, input and change. */
export async function select(target: Target, value: string) {
  const element = find<HTMLSelectElement>(target);
  element.focus();
  element.value = value;
  fire(element, 'input');
  fire(element, 'change');
  await settled();
}

/** Ember's triggerEvent(input, 'change', { files }) on a file input. */
export async function chooseFiles(target: Target, files: File[]) {
  const input = find<HTMLInputElement>(target);
  const data = new DataTransfer();
  files.forEach((file) => data.items.add(file));
  input.files = data.files;
  fire(input, 'change');
  await settled();
}
