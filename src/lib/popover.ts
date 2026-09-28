import { popIn } from './motion.ts';

/** The side of the anchor a popover opens on, then the edge both share; no edge centres it. */
export type CanonPlacement =
  | 'top'
  | 'top-start'
  | 'top-end'
  | 'bottom'
  | 'bottom-start'
  | 'bottom-end'
  | 'left'
  | 'left-start'
  | 'left-end'
  | 'right'
  | 'right-start'
  | 'right-end';

const sides = {
  top: { area: 'block-start', along: 'inline', gap: 'margin-block-end' },
  bottom: { area: 'block-end', along: 'inline', gap: 'margin-block-start' },
  left: { area: 'inline-start', along: 'block', gap: 'margin-inline-end' },
  right: { area: 'inline-end', along: 'block', gap: 'margin-inline-start' },
} as const;

/** CSS anchor positioning for a placement: the area, its fallbacks, and the margin that makes the gap. */
export function placementStyle(placement: CanonPlacement) {
  const [side, edge] = placement.split('-') as [
    keyof typeof sides,
    'start' | 'end' | undefined,
  ];
  const { area, along, gap } = sides[side];
  // start: shares the anchor's start edge, so it grows towards the end
  const span = edge === 'start' ? 'end' : edge === 'end' ? 'start' : undefined;
  const flips =
    along === 'inline'
      ? 'flip-block, flip-inline, flip-block flip-inline'
      : 'flip-inline, flip-block, flip-inline flip-block';
  return {
    area: span ? `${area} span-${along}-${span}` : area,
    fallbacks: flips,
    gap,
  };
}

export interface AttachOptions {
  placement: CanonPlacement;
  /** The anchor is a button that toggles the panel natively (popovertarget) and shows aria-expanded. */
  invokes?: boolean;
  /** Space between anchor and panel; default --canon-popover-gap. */
  gap?: string;
  /** Takes focus back when the panel closes with focus inside it; default the anchor. */
  returnFocus?: () => Element | null | undefined;
}

let anchors = 0;

function names(element: HTMLElement): string[] {
  const value = element.style.getPropertyValue('anchor-name');
  return value ? value.split(',').map((name) => name.trim()) : [];
}

/**
 * Anchors `panel` (a `[popover]`) to `anchor` and returns the undo. The
 * panel pops in on open and hands focus back when it closes.
 */
export function attach(
  panel: HTMLElement,
  anchor: HTMLElement,
  options: AttachOptions,
): () => void {
  const name = `--canon-anchor-${++anchors}`;
  // one element can anchor a tooltip and a menu
  anchor.style.setProperty('anchor-name', [...names(anchor), name].join(', '));
  const { area, fallbacks, gap } = placementStyle(options.placement);
  panel.style.setProperty('position-anchor', name);
  panel.style.setProperty('position-area', area);
  panel.style.setProperty('position-try-fallbacks', fallbacks);
  panel.style.setProperty(gap, options.gap ?? 'var(--canon-popover-gap)');

  const button =
    options.invokes && anchor instanceof HTMLButtonElement ? anchor : undefined;
  if (button) {
    button.popoverTargetElement = panel;
    button.setAttribute('aria-controls', panel.id);
    button.setAttribute('aria-expanded', 'false');
  }

  let hadFocus = false;
  const before = (event: ToggleEvent) => {
    if (event.newState === 'open') return popIn(panel);
    hadFocus = panel.contains(document.activeElement);
  };
  const toggle = (event: ToggleEvent) => {
    const open = event.newState === 'open';
    button?.setAttribute('aria-expanded', String(open));
    if (open || !hadFocus) return;
    const focused = document.activeElement;
    if (focused && focused !== document.body && !panel.contains(focused))
      return;
    const target = options.returnFocus ? options.returnFocus() : anchor;
    if (target instanceof HTMLElement) target.focus({ preventScroll: true });
  };
  panel.addEventListener('beforetoggle', before);
  panel.addEventListener('toggle', toggle);

  return () => {
    panel.removeEventListener('beforetoggle', before);
    panel.removeEventListener('toggle', toggle);
    const rest = names(anchor).filter((other) => other !== name);
    if (rest.length) anchor.style.setProperty('anchor-name', rest.join(', '));
    else anchor.style.removeProperty('anchor-name');
    for (const property of [
      'position-anchor',
      'position-area',
      'position-try-fallbacks',
      gap,
    ])
      panel.style.removeProperty(property);
    if (button) {
      button.popoverTargetElement = null;
      button.removeAttribute('aria-controls');
      button.removeAttribute('aria-expanded');
    }
  };
}

/** The panel a trigger modifier opens: rendered beside the trigger, found by id. */
export function panelFor(trigger: Element, id: string): HTMLElement {
  const root = trigger.getRootNode() as Document | ShadowRoot;
  const panel = root.getElementById(id);
  if (!panel) throw new Error(`no popover #${id} beside its trigger`);
  return panel;
}

export function isOpen(panel: Element): boolean {
  return panel.matches(':popover-open');
}

export function hide(panel: HTMLElement) {
  if (isOpen(panel)) panel.hidePopover();
}
