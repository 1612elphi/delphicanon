import {
  createApp,
  defineComponent,
  nextTick,
  type App,
  type Component,
} from 'vue';
import { toast } from '../../src/lib/toast-store.ts';

let mounted: { app: App; host: HTMLElement }[] = [];
const write = toast.write;

/**
 * Mounts an inline template. Every scope entry is available to the
 * template; PascalCase entries are also registered as components.
 */
export async function render(
  template: string,
  scope: Record<string, unknown> = {},
): Promise<HTMLElement> {
  const components = Object.fromEntries(
    Object.entries(scope).filter(([name]) => /^[A-Z]/.test(name)),
  ) as Record<string, Component>;
  const host = document.createElement('div');
  host.className = 'test-root';
  document.body.append(host);
  const app = createApp(
    defineComponent({ components, setup: () => scope, template }),
  );
  app.mount(host);
  mounted.push({ app, host });
  await settled();
  return host;
}

export function cleanup() {
  for (const { app, host } of mounted) {
    app.unmount();
    host.remove();
  }
  mounted = [];
  toast.write = write;
  toast.visible = false;
  toast.detail = undefined;
  toast.shown = 0;
}

/** Waits for Vue's next render and for pending promise callbacks. */
export async function settled() {
  await nextTick();
  await new Promise((resolve) => setTimeout(resolve, 0));
  await nextTick();
}

type Target = string | Element;

export function find<E extends Element = HTMLElement>(target: Target): E {
  const element =
    typeof target === 'string' ? document.querySelector<E>(target) : target;
  if (!element) throw new Error(`no element matches ${String(target)}`);
  return element as E;
}

export function findAll<E extends Element = HTMLElement>(selector: string) {
  return [...document.querySelectorAll<E>(selector)];
}

function build(type: string, init: Record<string, unknown>): Event {
  const options = { bubbles: true, cancelable: true, composed: true, ...init };
  if (type.startsWith('pointer')) return new PointerEvent(type, options);
  if (type.startsWith('mouse') || type === 'click' || type === 'contextmenu')
    return new MouseEvent(type, options);
  if (type.startsWith('key')) return new KeyboardEvent(type, options);
  if (type === 'wheel') return new WheelEvent(type, options);
  if (type.startsWith('focus') || type === 'blur')
    return new FocusEvent(type, options);
  if (type === 'input' || type === 'beforeinput')
    return new InputEvent(type, options);
  return new Event(type, options);
}

export async function triggerEvent(
  target: Target,
  type: string,
  init: Record<string, unknown> = {},
) {
  find(target).dispatchEvent(build(type, init));
  await settled();
}

export async function triggerKeyEvent(
  target: Target,
  type: 'keydown' | 'keyup' | 'keypress',
  key: string,
  modifiers: Partial<
    Record<'shiftKey' | 'altKey' | 'ctrlKey' | 'metaKey', boolean>
  > = {},
) {
  await triggerEvent(target, type, { key, ...modifiers });
}

/**
 * mousedown, focus, mouseup and click, as @ember/test-helpers sends them (no
 * pointer events). Throws on a disabled element.
 */
export async function click(target: Target) {
  const element = find(target);
  if (element.matches(':disabled'))
    throw new Error(`cannot click a disabled element`);
  const at = { button: 0 };
  const down = build('mousedown', at);
  element.dispatchEvent(down);
  if (!down.defaultPrevented && element instanceof HTMLElement) element.focus();
  element.dispatchEvent(build('mouseup', at));
  element.dispatchEvent(build('click', at));
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

/** Sets a field's value and sends input and change. */
export async function fillIn(target: Target, value: string) {
  const element = find<HTMLInputElement | HTMLTextAreaElement>(target);
  element.focus();
  element.value = value;
  element.dispatchEvent(build('input', {}));
  element.dispatchEvent(build('change', {}));
  await settled();
}

/** Picks an option of a native select and sends input and change. */
export async function select(target: Target, value: string) {
  const element = find<HTMLSelectElement>(target);
  element.value = value;
  element.dispatchEvent(build('input', {}));
  element.dispatchEvent(build('change', {}));
  await settled();
}

export async function waitUntil<T>(
  check: () => T,
  { timeout = 2000 } = {},
): Promise<T> {
  const start = performance.now();
  for (;;) {
    const result = check();
    if (result) return result;
    if (performance.now() - start > timeout)
      throw new Error('waitUntil timed out');
    await new Promise((resolve) => setTimeout(resolve, 10));
  }
}

export const wait = (ms: number) =>
  new Promise((resolve) => setTimeout(resolve, ms));
