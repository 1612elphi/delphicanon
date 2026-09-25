import {
  clamped,
  cmyk,
  fromCmyk,
  fromHsb,
  fromHsl,
  fromLab,
  fromLch,
  fromOklab,
  fromOklch,
  hsb,
  hsl,
  lab,
  lch,
  oklab,
  oklch,
  type Rgb,
  type Triple,
} from './colour.ts';

/**
 * The spaces of CanonColourSolid (Swift `CanonColourSolid.Space`), named by
 * their Swift cases and listed in picker order.
 */
export type SolidSpace =
  'rgb' | 'hsl' | 'hsb' | 'oklch' | 'oklab' | 'lch' | 'lab' | 'cmyk';

export const solidSpaces: SolidSpace[] = [
  'rgb',
  'hsl',
  'hsb',
  'oklch',
  'oklab',
  'lch',
  'lab',
  'cmyk',
];

export const spaceNames: Record<SolidSpace, string> = {
  rgb: 'RGB',
  hsl: 'HSL',
  hsb: 'HSB',
  oklch: 'OKLCH',
  oklab: 'OKLab',
  lch: 'LCH',
  lab: 'Lab',
  cmyk: 'CMYK',
};

/**
 * A pick's channels, each 0...1 (chroma may pass 1). Order: RGB r g b; HSL h
 * l s; Lab and OKLab a L b; CMYK c m y k; the rest hue, radius, height. Only
 * CMYK uses the fourth.
 */
export type SolidPoint = [number, number, number, number];

/** CanonColourSolid.Geometry */
export const oklabReach = 0.33;
export const labReach = 110;

export interface SolidChannel {
  name: string;
  /** Slider range, in the channel's own units. */
  min: number;
  max: number;
  /** Index into the point. */
  axis: number;
  /** Units per 1 of the point. */
  scale: number;
  decimals: number;
  /** Channel value at 0 of the point. */
  offset: number;
  /** Second line under the name. */
  detail?: string;
}

function channel(
  name: string,
  max: number,
  axis: number,
  decimals = 0,
  scale = max,
): SolidChannel {
  return { name, min: 0, max, axis, scale, decimals, offset: 0 };
}

// a green/pink, b blue/yellow
function opponent(
  name: string,
  detail: string,
  axis: number,
  reach: number,
  decimals: number,
): SolidChannel {
  return {
    name,
    detail,
    min: -reach,
    max: reach,
    axis,
    scale: reach * 2,
    decimals,
    offset: -reach,
  };
}

const hue = channel('Hue', 360, 0);

/** The channels in the order a tool lists them. */
export function channels(space: SolidSpace): SolidChannel[] {
  switch (space) {
    case 'rgb':
      return [
        channel('Red', 255, 0),
        channel('Green', 255, 1),
        channel('Blue', 255, 2),
      ];
    case 'hsl':
      return [hue, channel('Saturation', 100, 2), channel('Lightness', 100, 1)];
    case 'hsb':
      return [
        hue,
        channel('Saturation', 100, 1),
        channel('Brightness', 100, 2),
      ];
    case 'oklch':
      return [
        channel('Lightness', 1, 2, 2),
        channel('Chroma', oklabReach, 1, 3),
        hue,
      ];
    case 'oklab':
      return [
        channel('Lightness', 1, 1, 2),
        opponent('Component A', 'Pink-Green', 0, oklabReach, 3),
        opponent('Component B', 'Blue-Yellow', 2, oklabReach, 3),
      ];
    case 'lab':
      return [
        channel('Lightness', 100, 1),
        opponent('Component A', 'Pink-Green', 0, labReach, 0),
        opponent('Component B', 'Blue-Yellow', 2, labReach, 0),
      ];
    case 'cmyk':
      return [
        channel('Cyan', 100, 0),
        channel('Magenta', 100, 1),
        channel('Yellow', 100, 2),
        channel('Black', 100, 3),
      ];
    case 'lch':
      return [
        channel('Lightness', 100, 2),
        // srgb blue reaches 134
        channel('Chroma', 134, 1, 0, labReach),
        hue,
      ];
  }
}

/** Channels run along the box's edges; the rest are hue, radius and height. */
export function isCartesian(space: SolidSpace): boolean {
  return ['rgb', 'hsl', 'oklab', 'lab', 'cmyk'].includes(space);
}

export function colourAt(space: SolidSpace, [x, y, z, w]: SolidPoint): Triple {
  const h = (x - Math.floor(x)) * 360;
  switch (space) {
    case 'cmyk':
      return fromCmyk(x, y, z, w);
    case 'rgb':
      return [x, y, z];
    case 'hsl':
      return fromHsl(h, z * 100, y * 100);
    case 'hsb':
      return fromHsb(h, y, z);
    case 'oklch':
      return fromOklch(z, y * oklabReach, h);
    case 'lch':
      return fromLch(z * 100, y * labReach, h);
    case 'oklab':
      return fromOklab(y, (x * 2 - 1) * oklabReach, (z * 2 - 1) * oklabReach);
    case 'lab':
      return fromLab(y * 100, (x * 2 - 1) * labReach, (z * 2 - 1) * labReach);
  }
}

export function pointFor(space: SolidSpace, colour: Rgb): SolidPoint {
  switch (space) {
    case 'cmyk':
      return cmyk(colour);
    case 'rgb':
      return [...clamped(colour), 0];
    case 'hsl': {
      const [h, s, l] = hsl(colour);
      return [h / 360, l / 100, s / 100, 0];
    }
    case 'hsb': {
      const [h, s, b] = hsb(colour);
      return [h / 360, s, b, 0];
    }
    case 'oklch': {
      const [l, c, h] = oklch(colour);
      return [h / 360, c / oklabReach, l, 0];
    }
    case 'lch': {
      const [l, c, h] = lch(colour);
      return [h / 360, c / labReach, l / 100, 0];
    }
    case 'oklab': {
      const [l, a, b] = oklab(colour);
      return [(a / oklabReach + 1) / 2, l, (b / oklabReach + 1) / 2, 0];
    }
    case 'lab': {
      const [l, a, b] = lab(colour);
      return [(a / labReach + 1) / 2, l / 100, (b / labReach + 1) / 2, 0];
    }
  }
}

/** `point` in `from` moved to `to`, through the colour it names. */
export const convertPoint = (
  from: SolidSpace,
  to: SolidSpace,
  point: SolidPoint,
): SolidPoint => pointFor(to, colourAt(from, point));
