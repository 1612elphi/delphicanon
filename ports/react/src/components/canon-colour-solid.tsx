import {
  useCallback,
  useLayoutEffect,
  useState,
  type HTMLAttributes,
  type Ref,
  type RefObject,
} from 'react';
import {
  createRenderer,
  type Renderer,
} from '@canon/lib/colour-solid/shader.ts';
import {
  SolidState,
  solidMotion,
  type Overlays,
} from '@canon/lib/colour-solid/solid.ts';
import { hex, takesBlackInk, type Rgb } from '@canon/lib/colour.ts';
import { capture } from '@canon/lib/motion.ts';
import {
  colourAt,
  pointFor,
  spaceNames,
  type SolidSpace as Space,
} from '@canon/lib/colour-space.ts';
import { identity, type Mat3, type Vec4 } from '@canon/lib/colour-solid/vec.ts';
import { cx } from '../lib/class-names.ts';
import { useLatest, useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-colour-solid.css';

export interface CanonColourSolidProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'onChange'
> {
  /** Default `hsl`. */
  space?: Space;
  /**
   * The picked colour's channels, each 0...1 (chroma may pass 1), in
   * `space`'s units. Order: rgb r g b; hsl h l s; lab and oklab a L b;
   * cmyk c m y k; the rest hue, radius, height. Only cmyk uses the fourth.
   * A new `space` with an unchanged `point` converts the pick and reports
   * it through `onChange`. Default: a dark green.
   */
  point?: readonly number[];
  /** A change of `point` eases the drawing to it (`setPoint(_:animated:)`), as for a tap on a slider track. */
  animated?: boolean;
  /**
   * Index into `point` of the channel to slice along, 0...2. The solid
   * draws faint, the slice through the pick opaque, and a tap or a drag
   * picks on the slice; nothing is cut away. CMYK's black has no slice:
   * see `showsWhole`.
   */
  sliceAxis?: number | null;
  /**
   * Turns the slice to face the viewer and flattens the view, so a drag on
   * the slice moves the pick as on a 2D picker. A chroma or saturation
   * shell unrolls into a flat sheet.
   */
  isOrtho?: boolean;
  /** Fades the solid around a slice to opaque, while black changes. */
  showsWhole?: boolean;
  /** Without a slice, cuts away the part between the pick and the viewer. Default true. */
  cutsAway?: boolean;
  /** Further colours, drawn as small squares, hollow where the solid hides them. */
  marks?: readonly Rgb[];
  /**
   * Rows of a 3x3 matrix on sRGB that every drawn colour goes through
   * (`setVision(_:animated:)`); changes ease. Default identity.
   */
  vision?: readonly (readonly number[])[];
  /** After every pick, with the new point and its colour. */
  onChange?: (point: Vec4, colour: Rgb) => void;
  /** Nearest colour name, read out before the hex value. */
  closestName?: (colour: Rgb) => string;
  ref?: Ref<HTMLDivElement>;
}

interface Synced {
  space?: Space;
  point?: readonly number[];
  marks?: readonly Rgb[];
}

type Args = Pick<
  CanonColourSolidProps,
  | 'space'
  | 'point'
  | 'animated'
  | 'sliceAxis'
  | 'isOrtho'
  | 'showsWhole'
  | 'cutsAway'
  | 'marks'
  | 'vision'
>;

type Callbacks = Pick<CanonColourSolidProps, 'onChange' | 'closestName'>;

/** Travel in px before a press becomes a drag, as UIPanGestureRecognizer's slop. */
const dragSlop = 10;
/** Pointer history in ms used for the fling speed. */
const flingWindow = 100;

const reducedMotion = () =>
  window.matchMedia('(prefers-reduced-motion: reduce)').matches;

const sameValues = (a?: readonly number[], b?: readonly number[]) =>
  a === b ||
  (!!a && !!b && a.length === b.length && a.every((v, i) => v === b[i]));

const css = (c: Rgb) => `color(srgb ${c.map((v) => v.toFixed(4)).join(' ')})`;

/** The Ember component's state and drawing, outside React's render. */
class SolidView {
  state: SolidState;
  #callbacks?: RefObject<Callbacks>;
  #synced?: Synced;
  #root?: HTMLDivElement;
  #canvas?: HTMLCanvasElement;
  #renderer?: Renderer;
  #frame = 0;
  #last?: number;
  #valueText = '';

  constructor(space: Space, point: Vec4) {
    this.state = new SolidState(space, point, () => this.redraw());
  }

  redraw() {
    if (this.#root && !this.#frame) {
      this.#frame = requestAnimationFrame(this.#draw);
    }
  }

  #draw = (now: number) => {
    this.#frame = 0;
    const dt =
      this.#last === undefined ? 0 : Math.max(0, now - this.#last) / 1000;
    this.state.tick(dt);
    this.#last = this.state.animating ? now : undefined;
    this.paint();
  };

  /** Draws the solid and places the overlays now. */
  paint() {
    const root = this.#root;
    const canvas = this.#canvas;
    if (!root || !canvas) return;
    const width = root.clientWidth;
    const height = root.clientHeight;
    this.state.size = { width, height };
    const ratio = window.devicePixelRatio || 1;
    const pixels = [
      Math.round(width * ratio),
      Math.round(height * ratio),
    ] as const;
    if (canvas.width !== pixels[0] || canvas.height !== pixels[1]) {
      [canvas.width, canvas.height] = pixels;
    }
    if (width > 0 && height > 0) {
      this.#renderer?.draw(this.state.uniforms(...pixels), ...pixels);
    }
    place(root, this.state.overlays());
    const colour = colourAt(this.state.space, this.state.point);
    const name = this.#callbacks?.current.closestName?.(colour);
    const text = name ? `${name}, ${hex(colour)}` : hex(colour);
    if (text !== this.#valueText) {
      this.#valueText = text;
      root.querySelector('output')!.textContent = text;
    }
  }

  #notify() {
    const { point, space } = this.state;
    this.#callbacks?.current.onChange?.([...point], colourAt(space, point));
  }

  attach(root: HTMLDivElement, callbacks: RefObject<Callbacks>) {
    this.#root = root;
    this.#callbacks = callbacks;
    const state = this.state;
    // a lost context cannot be reused, and StrictMode attaches twice
    const canvas = document.createElement('canvas');
    canvas.className = 'canon-colour-solid-canvas';
    root.prepend(canvas);
    this.#canvas = canvas;
    this.#renderer = createRenderer(canvas);
    root.dataset['gl'] = this.#renderer ? 'ready' : 'none';

    const resize = new ResizeObserver(() => this.redraw());
    resize.observe(root);
    const motion = window.matchMedia('(prefers-reduced-motion: reduce)');
    const motionChanged = () => (state.animates = !motion.matches);
    motion.addEventListener('change', motionChanged);

    const local = (e: PointerEvent) => {
      const box = root.getBoundingClientRect();
      return {
        x: ((e.clientX - box.left) * root.clientWidth) / (box.width || 1),
        y: ((e.clientY - box.top) * root.clientHeight) / (box.height || 1),
      };
    };
    let drag:
      | {
          id: number;
          start: { x: number; y: number };
          last: { x: number; y: number };
          grabbed: boolean;
          active: boolean;
          picks: boolean;
          samples: { t: number; x: number; y: number }[];
        }
      | undefined;

    const down = (e: PointerEvent) => {
      if (e.button !== 0 || drag) return;
      const at = local(e);
      const grabbed = state.grabs(at);
      drag = {
        id: e.pointerId,
        start: at,
        last: at,
        grabbed,
        active: false,
        picks: false,
        samples: [{ t: e.timeStamp, ...at }],
      };
      if (grabbed) capture(root, e.pointerId);
    };
    const move = (e: PointerEvent) => {
      if (!drag || e.pointerId !== drag.id) return;
      const at = local(e);
      drag.samples.push({ t: e.timeStamp, ...at });
      drag.samples = drag.samples.filter(
        (s) => e.timeStamp - s.t <= flingWindow,
      );
      if (!drag.active) {
        const travel = Math.hypot(at.x - drag.start.x, at.y - drag.start.y);
        if (!drag.grabbed || travel < dragSlop) return;
        drag.active = true;
        state.stopSpin();
        drag.picks = state.nearPick(at) || !state.dragsTurn;
      }
      if (drag.picks) {
        // misses keep last pick
        if (state.pick(at)) this.#notify();
      } else {
        state.turn(
          (at.x - drag.last.x) * solidMotion.turnRate,
          (at.y - drag.last.y) * solidMotion.turnRate,
        );
      }
      drag.last = at;
    };
    const up = (e: PointerEvent) => {
      if (!drag || e.pointerId !== drag.id) return;
      const at = local(e);
      if (drag.active && !drag.picks) {
        const first = drag.samples.find(
          (s) => e.timeStamp - s.t <= flingWindow,
        );
        const seconds = first ? (e.timeStamp - first.t) / 1000 : 0;
        if (first && seconds > 0) {
          state.startSpin(
            ((at.x - first.x) / seconds) * solidMotion.turnRate,
            ((at.y - first.y) / seconds) * solidMotion.turnRate,
          );
        }
      } else if (
        !drag.active &&
        Math.hypot(at.x - drag.start.x, at.y - drag.start.y) < dragSlop &&
        state.pick(at)
      ) {
        this.#notify();
      }
      drag = undefined;
    };
    const cancel = () => (drag = undefined);
    const key = (e: KeyboardEvent) => {
      const turns: Record<string, [number, number]> = {
        ArrowLeft: [-solidMotion.keyTurn, 0],
        ArrowRight: [solidMotion.keyTurn, 0],
        ArrowUp: [0, -solidMotion.keyTurn],
        ArrowDown: [0, solidMotion.keyTurn],
      };
      const turn = turns[e.key];
      if (!turn || !state.dragsTurn) return;
      e.preventDefault();
      state.stopSpin();
      state.turn(...turn);
    };

    root.addEventListener('pointerdown', down);
    root.addEventListener('pointermove', move);
    root.addEventListener('pointerup', up);
    root.addEventListener('pointercancel', cancel);
    root.addEventListener('keydown', key);
    this.paint();

    return () => {
      cancelAnimationFrame(this.#frame);
      this.#frame = 0;
      this.#root = undefined;
      resize.disconnect();
      motion.removeEventListener('change', motionChanged);
      root.removeEventListener('pointerdown', down);
      root.removeEventListener('pointermove', move);
      root.removeEventListener('pointerup', up);
      root.removeEventListener('pointercancel', cancel);
      root.removeEventListener('keydown', key);
      this.#renderer?.destroy();
      this.#renderer = undefined;
      canvas.remove();
      this.#canvas = undefined;
      this.#valueText = '';
    };
  }

  sync(args: Args) {
    const state = this.state;
    const synced = this.#synced;
    // first arguments: no motion
    state.animates = synced !== undefined && !reducedMotion();
    const space = args.space ?? 'hsl';
    const pointChanged = !sameValues(args.point, synced?.point);
    if (space !== state.space) {
      state.setSpace(space);
      if (!pointChanged) queueMicrotask(() => this.#notify());
    }
    if (args.point && pointChanged && !sameValues(args.point, state.point)) {
      state.setPoint([...args.point] as Vec4, args.animated ?? false);
    }
    state.setVision((args.vision as Mat3 | undefined) ?? identity, true);
    if (args.marks !== synced?.marks) state.setMarks([...(args.marks ?? [])]);
    state.setCutsAway(args.cutsAway ?? true);
    // controls order: ortho, then slice
    state.setOrtho(args.isOrtho ?? false);
    state.setSliceAxis(args.sliceAxis ?? null);
    state.setShowsWhole(args.showsWhole ?? false);
    state.animates = !reducedMotion();
    this.#synced = { space, point: args.point, marks: args.marks };
  }
}

/**
 * A colour space drawn as a solid: drag to turn it, tap a face to pick the
 * colour there, drag from the pick to move it over the faces. The part of
 * the solid between the pick and the viewer is cut away. CMYK has four
 * channels: black is depth, and the CMY cube shrinks inside a wireframe of
 * black's range.
 */
export default function CanonColourSolid({
  space,
  point,
  animated,
  sliceAxis,
  isOrtho,
  showsWhole,
  cutsAway,
  marks,
  vision,
  onChange,
  closestName,
  className,
  ref,
  ...rest
}: CanonColourSolidProps) {
  const [view] = useState(
    () =>
      new SolidView(
        space ?? 'hsl',
        (point as Vec4 | undefined) ??
          pointFor(space ?? 'hsl', [0.12, 0.4, 0.15]),
      ),
  );
  const callbacks = useLatest<Callbacks>({ onChange, closestName });

  const setup = useCallback(
    (root: HTMLDivElement) => view.attach(root, callbacks),
    [view, callbacks],
  );

  useLayoutEffect(
    () =>
      view.sync({
        space,
        point,
        animated,
        sliceAxis,
        isOrtho,
        showsWhole,
        cutsAway,
        marks,
        vision,
      }),
    [
      view,
      space,
      point,
      animated,
      sliceAxis,
      isOrtho,
      showsWhole,
      cutsAway,
      marks,
      vision,
    ],
  );

  return (
    <div
      className={cx(
        'canon-colour-solid',
        showsWhole && 'canon-colour-solid--whole',
        className,
      )}
      tabIndex={0}
      role="group"
      aria-label={spaceNames[space ?? 'hsl']}
      ref={useRefs(setup, ref)}
      {...rest}
    >
      <svg className="canon-colour-solid-wire" aria-hidden="true">
        <path />
      </svg>
      <div className="canon-colour-solid-overlay" aria-hidden="true">
        <span className="canon-colour-solid-marker canon-colour-solid-marker--pick" />
      </div>
      <output className="canon-colour-solid-value" aria-live="polite" />
    </div>
  );
}

/** Moves the markers, letters and wireframe to where the state puts them. */
function place(root: HTMLElement, overlays: Overlays) {
  const layer = root.querySelector<HTMLElement>('.canon-colour-solid-overlay')!;
  const pick = layer.querySelector<HTMLElement>(
    '.canon-colour-solid-marker--pick',
  )!;
  mark(pick, overlays.pick.at, overlays.pick.colour);

  const marks = [
    ...layer.querySelectorAll<HTMLElement>('.canon-colour-solid-marker--mark'),
  ];
  while (marks.length < overlays.marks.length) {
    const view = document.createElement('span');
    view.className =
      'canon-colour-solid-marker canon-colour-solid-marker--mark';
    layer.insertBefore(view, pick);
    marks.push(view);
  }
  marks.forEach((view, i) => {
    const m = overlays.marks[i];
    if (m) mark(view, m.at, m.colour);
    else view.hidden = true;
  });

  const labels = [
    ...layer.querySelectorAll<HTMLElement>('.canon-colour-solid-axis'),
  ];
  while (labels.length < overlays.labels.length) {
    const label = document.createElement('span');
    label.className = 'canon-colour-solid-axis';
    layer.prepend(label);
    labels.push(label);
  }
  labels.forEach((label, i) => {
    const l = overlays.labels[i];
    label.hidden = !l?.at || overlays.labelsHidden;
    if (!l?.at) return;
    label.textContent = l.letter;
    label.style.translate = `${l.at.x}px ${l.at.y}px`;
    // k fades with wireframe
    label.classList.toggle('canon-colour-solid-axis--depth', i === 3);
  });

  const path = root.querySelector('.canon-colour-solid-wire path')!;
  path.setAttribute('d', overlays.tesseract ?? '');
}

function mark(
  view: HTMLElement,
  at: { x: number; y: number; hidden: boolean } | undefined,
  colour: Rgb,
) {
  view.hidden = !at;
  if (!at) return;
  view.style.translate = `${at.x}px ${at.y}px`;
  view.style.backgroundColor = at.hidden ? '' : css(colour);
  view.dataset['ink'] = takesBlackInk(colour) ? 'black' : 'white';
  view.toggleAttribute('data-hollow', at.hidden);
}
