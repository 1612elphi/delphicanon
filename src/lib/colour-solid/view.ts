import { innerSize, type Geometry } from './geometry.ts';
import type { SolidSpace as Space } from '../colour-space.ts';
import { add, cross, dot, normalize, scale, sub, type Vec3 } from './vec.ts';

export interface Aim {
  yaw: number;
  pitch: number;
  /** Camera distance in box units. */
  distance: number;
  /** Radius of the sphere the short side fits. */
  fit: number;
  lookAt: Vec3;
}

export interface Camera {
  position: Vec3;
  right: Vec3;
  up: Vec3;
  forward: Vec3;
  /** Half-tangents of the view, horizontal and vertical. */
  tan: [number, number];
}

export interface Size {
  width: number;
  height: number;
}

/** The view from `aim`; above 0, `flatness` widens it to hold a sheet unrolled from a shell of `sheetRadius`. */
export function camera(
  aim: Aim,
  size: Size,
  flatness = 0,
  sheetRadius = 0,
): Camera {
  const { yaw, pitch, distance, fit: radius } = aim;
  const forward: Vec3 = [
    -Math.cos(pitch) * Math.sin(yaw),
    -Math.sin(pitch),
    -Math.cos(pitch) * Math.cos(yaw),
  ];
  const position = sub(aim.lookAt, scale(forward, distance));
  // yaw-based: valid overhead
  const right: Vec3 = [Math.cos(yaw), 0, -Math.sin(yaw)];
  const up = cross(right, forward);
  // sphere fits short side
  const fit = (radius * 1.1) / Math.sqrt(distance * distance - radius * radius);
  const aspect = size.height > 0 ? size.width / size.height : 1;
  let tan: [number, number] =
    aspect < 1 ? [fit, fit / aspect] : [fit * aspect, fit];
  if (flatness > 0) {
    // unrolled: half-width pi r
    const halfWidth = 1 + (Math.max(1, Math.PI * sheetRadius) - 1) * flatness;
    const need = [(halfWidth * 1.1) / distance, 1.1 / distance] as const;
    const grow = Math.max(1, need[0] / tan[0], need[1] / tan[1]);
    tan = [tan[0] * grow, tan[1] * grow];
  }
  return { position, right, up, forward, tan };
}

/** Where `p` lands in a view of `size`, or undefined behind the camera. */
export function project(
  cam: Camera,
  size: Size,
  p: Vec3,
): { x: number; y: number } | undefined {
  const offset = sub(p, cam.position);
  const depth = dot(offset, cam.forward);
  if (depth <= 0) return undefined;
  const x = dot(offset, cam.right) / (depth * cam.tan[0]);
  const y = dot(offset, cam.up) / (depth * cam.tan[1]);
  return { x: ((x + 1) / 2) * size.width, y: ((1 - y) / 2) * size.height };
}

export function ray(
  cam: Camera,
  size: Size,
  point: { x: number; y: number },
): Vec3 {
  const x = (point.x / Math.max(size.width, 1)) * 2 - 1;
  const y = 1 - (point.y / Math.max(size.height, 1)) * 2;
  return normalize(
    add(
      add(cam.forward, scale(cam.right, x * cam.tan[0])),
      scale(cam.up, y * cam.tan[1]),
    ),
  );
}

/** Letters beside the solid, at points in its box. */
export function axisAnchors(
  space: Space,
  geometry: Geometry,
): [string, Vec3][] {
  const edge = -geometry.size;
  const reach = geometry.size + 0.22;
  switch (space) {
    case 'rgb':
      return [
        ['R', [reach, edge, edge]],
        ['G', [edge, reach, edge]],
        ['B', [edge, edge, reach]],
      ];
    case 'hsl':
      return [
        ['H', [reach, edge, edge]],
        ['L', [edge, reach, edge]],
        ['S', [edge, edge, reach]],
      ];
    case 'hsb':
      return [
        ['B', [0, reach, 0]],
        ['S', [reach, 1, 0]],
      ];
    case 'oklch':
    case 'lch':
      return [
        ['L', [0, reach, 0]],
        ['C', [reach, 0, 0]],
      ];
    case 'oklab':
    case 'lab':
      return [
        ['L', [0, reach, 0]],
        ['a', [reach, 0, 0]],
        ['b', [0, 0, reach]],
      ];
    case 'cmyk': {
      const k = (1 + innerSize) / 2 + 0.1;
      return [
        ['C', [reach, edge, edge]],
        ['M', [edge, reach, edge]],
        ['Y', [edge, edge, reach]],
        ['K', [k, k, k]],
      ];
    }
  }
}

/** Outer cube at 0 % black, inner cube at 100 %, and the edges joining their corners. */
export function tesseractEdges(): [Vec3, Vec3][] {
  const corners: Vec3[] = Array.from({ length: 8 }, (_, i) => [
    i & 1 ? 1 : -1,
    i & 2 ? 1 : -1,
    i & 4 ? 1 : -1,
  ]);
  const edges: [Vec3, Vec3][] = [];
  for (const size of [1, innerSize]) {
    for (let a = 0; a < 8; a++) {
      for (const bit of [1, 2, 4]) {
        if (!(a & bit))
          edges.push([
            scale(corners[a]!, size),
            scale(corners[a | bit]!, size),
          ]);
      }
    }
  }
  for (const corner of corners) edges.push([corner, scale(corner, innerSize)]);
  return edges;
}
