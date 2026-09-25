import { Geometry, march, Sheet } from './geometry.ts';
import {
  clamp01,
  colourAt,
  isCartesian,
  pointFor,
  radius,
  shaderIds,
  type Rgb,
  type Space,
} from './space.ts';
import {
  axisAnchors,
  camera,
  project,
  ray,
  tesseractEdges,
  type Aim,
  type Camera,
  type Size,
} from './view.ts';
import {
  identity,
  length,
  mixMat3,
  mulMat3,
  normalize,
  remainder,
  round,
  sameMat3,
  smooth,
  sub,
  xyz,
  type Mat3,
  type Vec3,
  type Vec4,
} from './vec.ts';

/** Timings in seconds, rates in radians. */
export const solidMotion = {
  /** Easing of `point` after an animated change. */
  pointEase: 0.25,
  /** From one vision matrix to the next. */
  visionEase: 0.35,
  /** For a new slice to grow out of the pick while the old one shrinks into it. */
  sliceTurn: 0.4,
  /** For a shell to unroll or roll up. */
  unrollTime: 0.6,
  /** The turn into and out of `isOrtho`. */
  orthoTurn: 0.55,
  /** For the solid around a slice to fade to opaque and back. */
  wholeFade: 0.2,
  pitchLimit: 1.45,
  /** Per px of drag. */
  turnRate: 0.009,
  /** Share of the fling speed kept after one second. */
  flingKeep: 0.02,
  /** Per arrow key press. */
  keyTurn: 0.1,
} as const;

/** Camera distance in box units; far enough in `isOrtho` that the perspective no longer shows. */
export const distances = { free: 6, ortho: 80 } as const;
/** Share of the dark side's brightness taken away by the light. */
const shading = 0.16;
/** Opacity of the solid around a slice. */
const ghostOpacity = 0.16;
/** Px from the pick marker's centre that grab the pick. */
const pickReach = 26;

type Link = 'point' | 'vision' | 'slice' | 'unroll' | 'aim' | 'spin' | 'fade';

export interface Placed {
  x: number;
  y: number;
  /** Behind the solid, or on the far side of a sheet. */
  hidden: boolean;
}

export interface Overlays {
  pick: { at?: Placed; colour: Rgb };
  marks: { at?: Placed; colour: Rgb }[];
  labels: { letter: string; at?: { x: number; y: number } }[];
  /** The sheet shows no axes. */
  labelsHidden: boolean;
  /** SVG path of CMYK's wireframe, in px. */
  tesseract?: string;
}

/**
 * The state of CanonColourSolid without the DOM: the camera, the eased
 * values and the picks. `redraw` runs after every change; `tick` advances
 * the running animations.
 */
export class SolidState {
  space: Space;
  /** The picked colour's channels; see `CanonColourSolidSignature`. */
  point: Vec4;
  /** The point as drawn; trails `point` while easing. */
  shown: Vec4;
  vision: Mat3 = identity;
  shownVision: Mat3 = identity;
  marks: Rgb[] = [];
  cutsAway = true;
  sliceAxis: number | null = null;
  isOrtho = false;
  showsWhole = false;
  yaw = 0.62;
  pitch = 0.42;
  size: Size = { width: 0, height: 0 };
  /** False snaps every change, for reduced motion and the first arguments. */
  animates = true;

  private links = new Set<Link>();
  private pointFrom: Vec4 = [0, 0, 0, 0];
  private pointProgress = 1;
  private visionFrom: Mat3 = identity;
  private visionProgress = 1;
  private markPoints: Vec4[] = [];
  private oldSlice: number | null = null;
  private sliceProgress = 1;
  /** 0 rolled, 1 flat, linear in time; `flatness` eases it. */
  private unroll = 0;
  private unrollTarget = 0;
  private afterUnroll?: () => void;
  private distance: number = distances.free;
  private fitRadius: number;
  private lookAt: Vec3 = [0, 0, 0];
  private freeAim?: Aim;
  private aimFrom?: Aim;
  private aimTo?: Aim;
  private aimProgress = 1;
  private ghost = ghostOpacity;
  private spin: [number, number] = [0, 0];

  constructor(
    space: Space,
    point: Vec4,
    private redraw: () => void,
  ) {
    this.space = space;
    this.point = [...point];
    this.shown = [...point];
    this.fitRadius = radius(space);
  }

  get animating() {
    return this.links.size > 0;
  }

  private start(link: Link) {
    this.links.add(link);
    this.redraw();
  }

  private stop(link: Link) {
    this.links.delete(link);
  }

  setSpace(space: Space) {
    if (space === this.space) return;
    const old = this.space;
    this.space = space;
    this.stopUnroll();
    // ease: per-space units
    this.stop('point');
    this.assignPoint(pointFor(space, colourAt(old, this.point)));
    this.markPoints = this.marks.map((m) => pointFor(space, m));
    // turn lands new size
    if (!this.isOrtho && this.aimTo) this.aimTo.fit = radius(space);
    if (this.freeAim) this.freeAim.fit = radius(space);
    if (this.isOrtho) this.reaim();
    else this.fitRadius = radius(space);
    this.redraw();
  }

  /** Animated, the drawing eases to `next`, as a slider's fill does after a tap on its track. */
  setPoint(next: Vec4, animated: boolean) {
    if (!animated || !this.animates) {
      this.stop('point');
      this.assignPoint(next);
      return;
    }
    this.pointFrom = [...this.shown];
    this.pointProgress = 0;
    this.assignPoint(next);
    this.shown = [...this.pointFrom];
    this.start('point');
  }

  private assignPoint(next: Vec4) {
    if (next.every((v, i) => v === this.point[i])) return;
    this.point = [...next];
    this.shown = [...next];
    this.followLeaf();
    this.redraw();
  }

  /** Every drawn colour goes through `matrix` (rows on r, g, b), then clamps. */
  setVision(matrix: Mat3, animated: boolean) {
    if (sameMat3(matrix, this.vision)) return;
    this.vision = matrix;
    if (!animated || !this.animates) {
      this.stop('vision');
      this.shownVision = matrix;
      this.redraw();
      return;
    }
    this.visionFrom = this.shownVision;
    this.visionProgress = 0;
    this.start('vision');
  }

  setMarks(marks: Rgb[]) {
    this.marks = marks;
    this.markPoints = marks.map((m) => pointFor(this.space, m));
    this.redraw();
  }

  setCutsAway(cutsAway: boolean) {
    if (cutsAway === this.cutsAway) return;
    this.cutsAway = cutsAway;
    this.redraw();
  }

  /** Index into `point` of the channel to slice along, 0...2, or null. */
  setSliceAxis(axis: number | null) {
    if (axis === this.sliceAxis) return;
    if (axis !== null && !(axis >= 0 && axis <= 2)) {
      throw new RangeError('slice axes are 0...2');
    }
    const previous = this.sliceAxis;
    this.sliceAxis = axis;
    if (previous !== null && axis !== null && this.animates) {
      this.oldSlice = previous;
      this.sliceProgress = 0;
      this.start('slice');
    }
    if (this.isOrtho) this.setUnroll(0, () => this.reaim());
    this.redraw();
  }

  setOrtho(isOrtho: boolean) {
    if (isOrtho === this.isOrtho) return;
    this.isOrtho = isOrtho;
    if (isOrtho) {
      this.freeAim = this.currentAim;
      this.reaim();
      this.fadeGhost();
    } else {
      this.setUnroll(0, () => {
        this.reaim();
        this.fadeGhost();
      });
    }
  }

  setShowsWhole(showsWhole: boolean) {
    if (showsWhole === this.showsWhole) return;
    this.showsWhole = showsWhole;
    this.fadeGhost();
    // frame the largest cube
    if (this.isOrtho) this.reaim();
    this.redraw();
  }

  /** Advances every running animation by `dt` seconds. */
  tick(dt: number) {
    for (const link of [...this.links]) {
      if (this.links.has(link)) this.step(link, dt);
    }
  }

  private step(link: Link, dt: number) {
    switch (link) {
      case 'point': {
        this.pointProgress = Math.min(
          1,
          this.pointProgress + dt / solidMotion.pointEase,
        );
        const eased = 1 - Math.pow(1 - this.pointProgress, 3);
        const delta = this.point.map((v, i) => v - this.pointFrom[i]!) as Vec4;
        // hue: shortest way
        if (!isCartesian(this.space)) delta[0] -= round(delta[0]);
        this.shown = this.pointFrom.map(
          (v, i) => v + delta[i]! * eased,
        ) as Vec4;
        this.followLeaf();
        if (this.pointProgress >= 1) {
          this.shown = [...this.point];
          this.stop('point');
        }
        break;
      }
      case 'vision': {
        this.visionProgress = Math.min(
          1,
          this.visionProgress + dt / solidMotion.visionEase,
        );
        this.shownVision = mixMat3(
          this.visionFrom,
          this.vision,
          smooth(this.visionProgress),
        );
        if (this.visionProgress >= 1) {
          this.shownVision = this.vision;
          this.stop('vision');
        }
        break;
      }
      case 'slice': {
        this.sliceProgress = Math.min(
          1,
          this.sliceProgress + dt / solidMotion.sliceTurn,
        );
        if (this.sliceProgress >= 1) {
          this.oldSlice = null;
          this.stop('slice');
        }
        break;
      }
      case 'unroll': {
        const stride = dt / solidMotion.unrollTime;
        this.unroll =
          this.unroll < this.unrollTarget
            ? Math.min(this.unroll + stride, this.unrollTarget)
            : Math.max(this.unroll - stride, this.unrollTarget);
        if (this.unroll === this.unrollTarget) this.finishUnroll();
        break;
      }
      case 'aim': {
        const from = this.aimFrom;
        const to = this.aimTo;
        if (!from || !to) return this.stop('aim');
        this.aimProgress = Math.min(
          1,
          this.aimProgress + dt / solidMotion.orthoTurn,
        );
        const e = smooth(this.aimProgress);
        const mix = (a: number, b: number) => a + (b - a) * e;
        this.apply({
          yaw: mix(from.yaw, to.yaw),
          pitch: mix(from.pitch, to.pitch),
          // log mix: even dolly
          distance: Math.exp(
            mix(Math.log(from.distance), Math.log(to.distance)),
          ),
          fit: mix(from.fit, to.fit),
          lookAt: from.lookAt.map((v, i) => mix(v, to.lookAt[i]!)) as Vec3,
        });
        if (this.aimProgress >= 1) {
          this.stop('aim');
          this.aimTo = undefined;
          if (this.wantsUnroll) this.setUnroll(1);
        }
        break;
      }
      case 'spin': {
        this.turn(this.spin[0] * dt, this.spin[1] * dt);
        const keep = Math.pow(solidMotion.flingKeep, dt);
        this.spin = [this.spin[0] * keep, this.spin[1] * keep];
        if (Math.hypot(...this.spin) < 0.05) this.stop('spin');
        break;
      }
      case 'fade': {
        const target = this.ghostTarget;
        const stride = dt / solidMotion.wholeFade;
        this.ghost =
          this.ghost < target
            ? Math.min(this.ghost + stride, target)
            : Math.max(this.ghost - stride, target);
        if (this.ghost === target) this.stop('fade');
        break;
      }
    }
    this.redraw();
  }

  private get wantsUnroll() {
    return this.isOrtho && this.sliceAxis === 1 && !isCartesian(this.space);
  }

  private get flatness() {
    return smooth(this.unroll);
  }

  /** The unrolling shell, undefined while rolled; faces the hue the camera looks at. */
  get sheet(): Sheet | undefined {
    return this.flatness > 0
      ? new Sheet(this.shown[1], Math.PI / 2 - this.yaw, 1 - this.flatness)
      : undefined;
  }

  private setUnroll(target: number, done?: () => void) {
    this.unrollTarget = target;
    this.afterUnroll = done;
    if (this.unroll === target || !this.animates) {
      this.unroll = target;
      this.finishUnroll();
      return;
    }
    this.start('unroll');
  }

  private finishUnroll() {
    this.stop('unroll');
    this.redraw();
    const done = this.afterUnroll;
    this.afterUnroll = undefined;
    done?.();
  }

  /** Flat at once, for a space change; a pending turn still runs. */
  private stopUnroll() {
    this.unrollTarget = 0;
    this.unroll = 0;
    this.finishUnroll();
  }

  private get currentAim(): Aim {
    return {
      yaw: this.yaw,
      pitch: this.pitch,
      distance: this.distance,
      fit: this.fitRadius,
      lookAt: [...this.lookAt],
    };
  }

  private reaim() {
    let target: Aim;
    if (this.isOrtho && this.sliceAxis !== null) {
      target = this.orthoAim(this.sliceAxis);
    } else {
      target = { ...(this.freeAim ?? this.currentAim) };
      target.distance = distances.free;
      target.fit = radius(this.space);
      target.lookAt = [0, 0, 0];
      if (!this.isOrtho) this.freeAim = undefined;
    }
    // shortest turn
    target.yaw += 2 * Math.PI * round((this.yaw - target.yaw) / (2 * Math.PI));
    this.stop('spin');
    if (!this.animates) {
      this.apply(target);
      if (this.wantsUnroll) this.setUnroll(1);
      return;
    }
    this.aimFrom = this.currentAim;
    this.aimTo = target;
    this.aimProgress = 0;
    this.start('aim');
  }

  /**
   * Faces the slice through the pick from the side the view is already on,
   * so the turn never passes edge on: a plane head on, the hue leaf square
   * to it, the height disc from above or below, the shell from outside at
   * the pick's hue.
   */
  private orthoAim(axis: number): Aim {
    // outer cube during black
    const size = this.showsWhole ? 1 : this.geometry().size;
    const aim = (
      yaws: number[],
      pitch: number,
      fit: number,
      lookAt: Vec3 = [0, 0, 0],
    ): Aim => {
      const off = (a: number) => Math.abs(remainder(a - this.yaw, 2 * Math.PI));
      const nearest = yaws.reduce((a, b) => (off(b) < off(a) ? b : a));
      return { yaw: nearest, pitch, distance: distances.ortho, fit, lookAt };
    };
    const overhead = this.pitch >= 0 ? Math.PI / 2 : -Math.PI / 2;
    if (isCartesian(this.space)) {
      if (axis === 0) return aim([-Math.PI / 2, Math.PI / 2], 0, size);
      if (axis === 1) return aim([this.yaw], overhead, size);
      return aim([0, Math.PI], 0, size);
    }
    const angle = this.shown[0] * 2 * Math.PI;
    if (axis === 0) {
      return aim([-angle, Math.PI - angle], 0, 1, [
        Math.cos(angle) * 0.5,
        0,
        Math.sin(angle) * 0.5,
      ]);
    }
    if (axis === 1) return aim([Math.PI / 2 - angle], 0, 1);
    return aim([this.yaw], overhead, 1);
  }

  /** In `isOrtho` a hue leaf turns with the hue, so it keeps facing the viewer. */
  private followLeaf() {
    if (!this.isOrtho || this.sliceAxis !== 0 || isCartesian(this.space))
      return;
    const target = this.orthoAim(0);
    if (this.links.has('aim')) this.aimTo = target;
    else this.apply(target);
  }

  private apply(aim: Aim) {
    this.yaw = aim.yaw;
    this.pitch = aim.pitch;
    this.distance = aim.distance;
    this.fitRadius = aim.fit;
    this.lookAt = aim.lookAt;
    this.redraw();
  }

  private get ghostTarget() {
    return this.showsWhole ? 1 : this.isOrtho ? 0 : ghostOpacity;
  }

  private fadeGhost() {
    if (!this.animates) {
      this.ghost = this.ghostTarget;
      this.redraw();
      return;
    }
    this.start('fade');
  }

  turn(dx: number, dy: number) {
    this.yaw -= dx;
    this.pitch = Math.min(
      Math.max(this.pitch + dy, -solidMotion.pitchLimit),
      solidMotion.pitchLimit,
    );
    this.redraw();
  }

  /** A fling, in radians per second. */
  startSpin(vx: number, vy: number) {
    if (Math.hypot(vx, vy) <= 0.3 || !this.animates) return;
    this.spin = [vx, vy];
    this.start('spin');
  }

  stopSpin() {
    this.stop('spin');
  }

  /** Drags turn the view; in `isOrtho` with a slice they move the pick instead. */
  get dragsTurn() {
    return !(this.isOrtho && this.sliceAxis !== null);
  }

  camera(size = this.size): Camera {
    return camera(this.currentAim, size, this.flatness, this.shown[1]);
  }

  private cut(): Vec4 {
    const position = this.camera().position;
    if (!this.cutsAway || this.sliceAxis !== null) return [0, 0, 0, 0];
    const sign = (v: number) => (v >= 0 ? 1 : -1);
    if (isCartesian(this.space)) {
      return [sign(position[0]), sign(position[1]), sign(position[2]), 1];
    }
    let towards =
      Math.atan2(position[2], position[0]) / (2 * Math.PI) - this.shown[0];
    towards -= round(towards);
    return [sign(towards), 0, sign(position[1]), 1];
  }

  geometry(): Geometry {
    return new Geometry(
      this.space,
      xyz(this.shown),
      this.cut(),
      this.sliceAxis,
      this.space === 'cmyk' ? this.shown[3] : 0,
    );
  }

  private hit(at: { x: number; y: number }): Vec3 | undefined {
    const cam = this.camera();
    const r = ray(cam, this.size, at);
    const t = march(cam.position, r, this.geometry());
    return t === undefined ? undefined : add3(cam.position, r, t);
  }

  /** Where a pointer meets the slice, or the solid when nothing is sliced. */
  private pickHit(at: { x: number; y: number }): Vec3 | undefined {
    if (this.sliceAxis === null) return this.hit(at);
    const cam = this.camera();
    const r = ray(cam, this.size, at);
    const geometry = this.geometry();
    const sheet = this.sheet;
    if (sheet) {
      return sheet
        .shellPoints(cam.position, r)
        .find((p) => geometry.shape(p) <= 1e-4);
    }
    const t = geometry.sliceHit(cam.position, r);
    return t === undefined ? undefined : add3(cam.position, r, t);
  }

  nearPick(at: { x: number; y: number }): boolean {
    const centre = this.place(this.shown);
    return (
      centre !== undefined &&
      Math.hypot(at.x - centre.x, at.y - centre.y) < pickReach
    );
  }

  /** Whether a drag from `at` begins: on the pick, or on the solid. */
  grabs(at: { x: number; y: number }): boolean {
    return (
      this.nearPick(at) ||
      (this.sheet ? this.pickHit(at) : this.hit(at)) !== undefined
    );
  }

  /** Picks the colour under `at`; false when nothing is there. */
  pick(at: { x: number; y: number }): boolean {
    const p = this.pickHit(at);
    if (!p) return false;
    let channels = this.geometry().channels(p);
    if (isCartesian(this.space)) channels = channels.map(clamp01) as Vec3;
    this.stop('point');
    const next: Vec4 = [...channels, this.point[3]];
    // slice axis fixed
    if (this.sliceAxis !== null)
      next[this.sliceAxis] = this.point[this.sliceAxis]!;
    this.assignPoint(next);
    return true;
  }

  /** `colour` as `vision` draws it. */
  seen(colour: Rgb): Rgb {
    const [r, g, b] = mulMat3(this.shownVision, [
      clamp01(colour.r),
      clamp01(colour.g),
      clamp01(colour.b),
    ]).map(clamp01) as Vec3;
    return { r, g, b };
  }

  private place(
    channels: Vec4,
    cam = this.camera(),
    geometry = this.geometry(),
  ): Placed | undefined {
    const sheet = this.sheet;
    if (sheet) {
      const placed = sheet.place(
        remainder(channels[0] * 2 * Math.PI - sheet.facing, 2 * Math.PI),
        channels[2] * 2 - 1,
      );
      const at = project(cam, this.size, placed.point);
      return at && { ...at, hidden: placed.far };
    }
    const box = xyz(channels);
    const p = new Geometry(
      this.space,
      box,
      [0, 0, 0, 0],
      null,
      this.space === 'cmyk' ? channels[3] : 0,
    ).display(box);
    const at = project(cam, this.size, p);
    if (!at) return undefined;
    // hollow when occluded
    const toward = sub(p, cam.position);
    const r = normalize(toward);
    const front =
      this.sliceAxis === null || this.showsWhole
        ? march(cam.position, r, geometry)
        : geometry.sliceHit(cam.position, r);
    return {
      ...at,
      hidden: front !== undefined && front < length(toward) - 0.08,
    };
  }

  overlays(): Overlays {
    const cam = this.camera();
    const geometry = this.geometry();
    const sheet = this.sheet;
    const tesseract =
      this.space === 'cmyk'
        ? tesseractEdges()
            .map(([a, b]) => [
              project(cam, this.size, a),
              project(cam, this.size, b),
            ])
            .filter(([a, b]) => a && b)
            .map(
              ([a, b]) =>
                `M${a!.x.toFixed(1)} ${a!.y.toFixed(1)}L${b!.x.toFixed(1)} ${b!.y.toFixed(1)}`,
            )
            .join('')
        : undefined;
    return {
      pick: {
        at: this.place(this.shown, cam, geometry),
        colour: this.seen(colourAt(this.space, this.shown)),
      },
      marks: this.marks.map((colour, i) => ({
        at: this.place(this.markPoints[i]!, cam, geometry),
        colour: this.seen(colour),
      })),
      labels: axisAnchors(this.space, geometry).map(([letter, anchor]) => ({
        letter,
        at: project(cam, this.size, anchor),
      })),
      labelsHidden: sheet !== undefined,
      tesseract,
    };
  }

  /** The 13 vec4 slots of the fragment shader's `u`, for a drawable of `width` by `height` px. */
  uniforms(width: number, height: number): Float32Array {
    const cam = this.camera({ width, height });
    const geometry = this.geometry();
    const reaches = this.sliceReaches(geometry);
    const v = this.shownVision;
    return new Float32Array([
      ...cam.position,
      0,
      ...cam.right,
      cam.tan[0],
      ...cam.up,
      cam.tan[1],
      ...cam.forward,
      0,
      ...geometry.pick,
      geometry.black,
      ...geometry.cut,
      shaderIds[this.space],
      shading,
      width,
      height,
      this.sliceAxis ?? -1,
      this.ghost,
      geometry.size,
      this.flatness,
      this.oldSlice ?? -1,
      reaches[0],
      reaches[1],
      Math.PI / 2 - this.yaw,
      ...geometry.display(geometry.pick),
      0,
      ...v[0],
      0,
      ...v[1],
      0,
      ...v[2],
      0,
    ]);
  }

  /** How far the new slice reaches from the pick, and the old one, while they swap. */
  private sliceReaches(geometry: Geometry): [number, number] {
    const { oldSlice, sliceAxis } = this;
    if (oldSlice === null || sliceAxis === null) return [1e6, 0];
    const eased = smooth(this.sliceProgress);
    return [
      this.extent(sliceAxis, geometry) * eased,
      this.extent(oldSlice, geometry) * (1 - eased),
    ];
  }

  /** Distance from the pick to the slice's farthest point, so both slices of a swap change over its whole length. */
  private extent(axis: number, geometry: Geometry) {
    const reach = geometry
      .display(geometry.pick)
      .map((v) => geometry.size + Math.abs(v)) as Vec3;
    // plane: fixed axis
    if (isCartesian(this.space)) reach[axis] = 0;
    return length(reach);
  }
}

const add3 = (o: Vec3, d: Vec3, t: number): Vec3 => [
  o[0] + d[0] * t,
  o[1] + d[1] * t,
  o[2] + d[2] * t,
];
