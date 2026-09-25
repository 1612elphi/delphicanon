export type Vec3 = [number, number, number];
export type Vec4 = [number, number, number, number];
/** Rows. */
export type Mat3 = [Vec3, Vec3, Vec3];

export const identity: Mat3 = [
  [1, 0, 0],
  [0, 1, 0],
  [0, 0, 1],
];

export const add = (a: Vec3, b: Vec3): Vec3 => [
  a[0] + b[0],
  a[1] + b[1],
  a[2] + b[2],
];
export const sub = (a: Vec3, b: Vec3): Vec3 => [
  a[0] - b[0],
  a[1] - b[1],
  a[2] - b[2],
];
export const scale = (a: Vec3, s: number): Vec3 => [
  a[0] * s,
  a[1] * s,
  a[2] * s,
];
export const dot = (a: Vec3, b: Vec3) =>
  a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
export const cross = (a: Vec3, b: Vec3): Vec3 => [
  a[1] * b[2] - a[2] * b[1],
  a[2] * b[0] - a[0] * b[2],
  a[0] * b[1] - a[1] * b[0],
];
export const length = (a: Vec3) => Math.sqrt(dot(a, a));
export const normalize = (a: Vec3): Vec3 => scale(a, 1 / length(a));
export const xyz = (a: Vec4): Vec3 => [a[0], a[1], a[2]];

export const mulMat3 = (m: Mat3, v: Vec3): Vec3 => [
  dot(m[0], v),
  dot(m[1], v),
  dot(m[2], v),
];

export const mixMat3 = (a: Mat3, b: Mat3, t: number): Mat3 =>
  a.map((row, i) => row.map((v, j) => v + (b[i]![j]! - v) * t)) as Mat3;

export const sameMat3 = (a: Mat3, b: Mat3) =>
  a.every((row, i) => row.every((v, j) => v === b[i]![j]));

/** As Swift's `remainder(_:_:)`: the result lies in -y/2...y/2. */
export const remainder = (x: number, y: number) => x - y * Math.round(x / y);

/** Smoothstep of 0...1. */
export const smooth = (t: number) => t * t * (3 - 2 * t);

/** Half away from zero, as Swift's `rounded()`. */
export const round = (x: number) => Math.sign(x) * Math.round(Math.abs(x));
