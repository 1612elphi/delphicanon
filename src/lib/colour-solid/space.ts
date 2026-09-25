import type { Vec3, Vec4 } from './vec.ts';

/** sRGB, each 0...1 when in gamut. */
export interface Rgb {
  r: number;
  g: number;
  b: number;
}

/** A colour space the solid draws, as `CanonColourSolid.Space`. */
export type Space =
  'rgb' | 'hsl' | 'hsb' | 'oklch' | 'oklab' | 'lch' | 'lab' | 'cmyk';

/** The order a picker lists them in. */
export const spaces: readonly Space[] = [
  'rgb',
  'hsl',
  'hsb',
  'oklch',
  'oklab',
  'lch',
  'lab',
  'cmyk',
];

export const spaceNames: Record<Space, string> = {
  rgb: 'RGB',
  hsl: 'HSL',
  hsb: 'HSB',
  oklch: 'OKLCH',
  oklab: 'OKLab',
  lch: 'LCH',
  lab: 'Lab',
  cmyk: 'CMYK',
};

/** The shader's space numbers. */
export const shaderIds: Record<Space, number> = {
  rgb: 0,
  hsl: 1,
  hsb: 2,
  oklch: 3,
  lch: 4,
  oklab: 5,
  lab: 6,
  cmyk: 7,
};

export const oklabReach = 0.33;
export const labReach = 110;

export interface Channel {
  name: string;
  /** Slider range, in the channel's own units. */
  range: [number, number];
  /** Index into `point`. */
  axis: number;
  /** Units per 1 of `point`. */
  scale: number;
  decimals: number;
  /** Channel value at 0 of `point`. */
  offset: number;
  /** Second line under the name. */
  detail?: string;
}

const channel = (
  name: string,
  range: [number, number],
  axis: number,
  scale: number,
  decimals: number,
  offset = 0,
  detail?: string,
): Channel => ({ name, range, axis, scale, decimals, offset, detail });

/** The channels in the order a tool lists them. */
export function channels(space: Space): Channel[] {
  const hue = channel('Hue', [0, 360], 0, 360, 0);
  const a = (reach: number, decimals: number) =>
    channel(
      'Component A',
      [-reach, reach],
      0,
      reach * 2,
      decimals,
      -reach,
      'Pink-Green',
    );
  const b = (reach: number, decimals: number) =>
    channel(
      'Component B',
      [-reach, reach],
      2,
      reach * 2,
      decimals,
      -reach,
      'Blue-Yellow',
    );
  switch (space) {
    case 'rgb':
      return [
        channel('Red', [0, 255], 0, 255, 0),
        channel('Green', [0, 255], 1, 255, 0),
        channel('Blue', [0, 255], 2, 255, 0),
      ];
    case 'hsl':
      return [
        hue,
        channel('Saturation', [0, 100], 2, 100, 0),
        channel('Lightness', [0, 100], 1, 100, 0),
      ];
    case 'hsb':
      return [
        hue,
        channel('Saturation', [0, 100], 1, 100, 0),
        channel('Brightness', [0, 100], 2, 100, 0),
      ];
    case 'oklch':
      return [
        channel('Lightness', [0, 1], 2, 1, 2),
        channel('Chroma', [0, oklabReach], 1, oklabReach, 3),
        hue,
      ];
    case 'oklab':
      return [
        channel('Lightness', [0, 1], 1, 1, 2),
        a(oklabReach, 3),
        b(oklabReach, 3),
      ];
    case 'lab':
      return [
        channel('Lightness', [0, 100], 1, 100, 0),
        a(labReach, 0),
        b(labReach, 0),
      ];
    case 'cmyk':
      return [
        channel('Cyan', [0, 100], 0, 100, 0),
        channel('Magenta', [0, 100], 1, 100, 0),
        channel('Yellow', [0, 100], 2, 100, 0),
        channel('Black', [0, 100], 3, 100, 0),
      ];
    case 'lch':
      return [
        channel('Lightness', [0, 100], 2, 100, 0),
        // srgb blue reaches 134
        channel('Chroma', [0, 134], 1, labReach, 0),
        hue,
      ];
  }
}

/** Channels run along the box's edges; the rest are hue, radius and height. */
export const isCartesian = (space: Space) =>
  space === 'rgb' ||
  space === 'hsl' ||
  space === 'oklab' ||
  space === 'lab' ||
  space === 'cmyk';

/** Largest distance of the solid from its centre. */
export function radius(space: Space): number {
  if (space === 'rgb' || space === 'hsl' || space === 'cmyk')
    return Math.sqrt(3);
  return space === 'hsb' ? Math.SQRT2 : 1.25;
}

/** The colour at `point`, in the order `CanonColourSolid.point` documents. */
export function colourAt(space: Space, point: Vec4): Rgb {
  const [x, y, z, w] = point;
  const hue = (x - Math.floor(x)) * 360;
  switch (space) {
    case 'cmyk':
      return {
        r: (1 - x) * (1 - w),
        g: (1 - y) * (1 - w),
        b: (1 - z) * (1 - w),
      };
    case 'rgb':
      return { r: x, g: y, b: z };
    case 'hsl':
      return fromHSL(hue, z * 100, y * 100);
    case 'hsb': {
      const [r, g, b] = hueRGB(hue / 360).map((c) => z * (1 - y + y * c));
      return { r: r!, g: g!, b: b! };
    }
    case 'oklch':
      return fromOKLCH(z, y * oklabReach, hue);
    case 'lch':
      return fromLCH(z * 100, y * labReach, hue);
    case 'oklab':
      return fromOKLAB(y, (x * 2 - 1) * oklabReach, (z * 2 - 1) * oklabReach);
    case 'lab':
      return fromLAB(y * 100, (x * 2 - 1) * labReach, (z * 2 - 1) * labReach);
  }
}

/** CMYK is the naive conversion: black takes the darkest channel, no ink limit or profile. */
export function pointFor(space: Space, colour: Rgb): Vec4 {
  const rgb: Vec3 = [clamp01(colour.r), clamp01(colour.g), clamp01(colour.b)];
  switch (space) {
    case 'cmyk': {
      const black = 1 - Math.max(...rgb);
      if (black >= 1) return [0, 0, 0, 1];
      const [c, m, y] = rgb.map((v) => (1 - v - black) / (1 - black));
      return [c!, m!, y!, black];
    }
    case 'rgb':
      return [...rgb, 0];
    case 'hsl': {
      const hsl = toHSL(colour);
      return [hsl.h / 360, hsl.l / 100, hsl.s / 100, 0];
    }
    case 'hsb': {
      const top = Math.max(...rgb);
      return [
        toHSL(colour).h / 360,
        top > 0 ? (top - Math.min(...rgb)) / top : 0,
        top,
        0,
      ];
    }
    case 'oklch': {
      const lch = polar(toOKLAB(colour));
      return [lch.h / 360, lch.c / oklabReach, lch.l, 0];
    }
    case 'lch': {
      const lch = polar(toLAB(colour));
      return [lch.h / 360, lch.c / labReach, lch.l / 100, 0];
    }
    case 'oklab': {
      const lab = toOKLAB(colour);
      return [
        (lab.a / oklabReach + 1) / 2,
        lab.l,
        (lab.b / oklabReach + 1) / 2,
        0,
      ];
    }
    case 'lab': {
      const lab = toLAB(colour);
      return [
        (lab.a / labReach + 1) / 2,
        lab.l / 100,
        (lab.b / labReach + 1) / 2,
        0,
      ];
    }
  }
}

/** `point` in `from` moved to `to`, through the colour it names. */
export const convertPoint = (from: Space, to: Space, point: Vec4): Vec4 =>
  pointFor(to, colourAt(from, point));

export function hueRGB(h: number): Vec3 {
  return [h * 6, h * 6 + 4, h * 6 + 2].map((k) =>
    clamp01(Math.abs(k - 6 * Math.floor(k / 6) - 3) - 1),
  ) as Vec3;
}

export const clamp01 = (v: number) => Math.min(Math.max(v, 0), 1);

export function hex(colour: Rgb): string {
  return (
    '#' +
    [colour.r, colour.g, colour.b]
      .map((v) =>
        Math.round(clamp01(v) * 255)
          .toString(16)
          .padStart(2, '0'),
      )
      .join('')
      .toUpperCase()
  );
}

/** Black type has more contrast on this colour than white. */
export function takesBlackInk(colour: Rgb): boolean {
  const l = relativeLuminance(colour);
  return (l + 0.05) / 0.05 >= 1.05 / (l + 0.05);
}

function relativeLuminance(colour: Rgb): number {
  const [r, g, b] = linear(colour);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function toHSL(colour: Rgb) {
  const [r, g, b] = [colour.r, colour.g, colour.b].map(clamp01) as Vec3;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const delta = max - min;
  const l = (max + min) / 2;
  if (delta <= 1e-10) return { h: 0, s: 0, l: l * 100 };
  const s = delta / (1 - Math.abs(2 * l - 1));
  let h =
    max === r
      ? 60 * (((g - b) / delta) % 6)
      : max === g
        ? 60 * ((b - r) / delta + 2)
        : 60 * ((r - g) / delta + 4);
  if (h < 0) h += 360;
  return { h, s: s * 100, l: l * 100 };
}

function fromHSL(h: number, s: number, l: number): Rgb {
  const s1 = s / 100;
  const l1 = l / 100;
  const c = (1 - Math.abs(2 * l1 - 1)) * s1;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = l1 - c / 2;
  const [r, g, b] =
    h >= 0 && h < 60
      ? [c, x, 0]
      : h >= 60 && h < 120
        ? [x, c, 0]
        : h >= 120 && h < 180
          ? [0, c, x]
          : h >= 180 && h < 240
            ? [0, x, c]
            : h >= 240 && h < 300
              ? [x, 0, c]
              : [c, 0, x];
  return { r: r + m, g: g + m, b: b + m };
}

const toLinear = (v: number) =>
  v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);

const fromLinear = (v: number) => {
  const c = Math.max(0, v);
  return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
};

const linear = (colour: Rgb): Vec3 =>
  [colour.r, colour.g, colour.b].map((v) => toLinear(clamp01(v))) as Vec3;

const fromLinearRGB = ([r, g, b]: Vec3): Rgb => ({
  r: fromLinear(r),
  g: fromLinear(g),
  b: fromLinear(b),
});

const d65: Vec3 = [0.95047, 1, 1.08883];

function labF(t: number) {
  const delta = 6 / 29;
  return t > delta * delta * delta
    ? Math.cbrt(t)
    : t / (3 * delta * delta) + 4 / 29;
}

export function labInverse(t: number) {
  const delta = 6 / 29;
  return t > delta ? t * t * t : 3 * delta * delta * (t - 4 / 29);
}

function toLAB(colour: Rgb) {
  const [r, g, b] = linear(colour);
  const x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b;
  const y = 0.2126729 * r + 0.7151522 * g + 0.072175 * b;
  const z = 0.0193339 * r + 0.119192 * g + 0.9503041 * b;
  const [fx, fy, fz] = [x / d65[0], y / d65[1], z / d65[2]].map(labF) as Vec3;
  return { l: 116 * fy - 16, a: 500 * (fx - fy), b: 200 * (fy - fz) };
}

/** Linear sRGB of a CIELAB colour, unclamped. */
export function labToLinear(l: number, a: number, b: number): Vec3 {
  const fy = (l + 16) / 116;
  const x = d65[0] * labInverse(a / 500 + fy);
  const y = d65[1] * labInverse(fy);
  const z = d65[2] * labInverse(fy - b / 200);
  return [
    3.2404542 * x - 1.5371385 * y - 0.4985314 * z,
    -0.969266 * x + 1.8760108 * y + 0.041556 * z,
    0.0556434 * x - 0.2040259 * y + 1.0572252 * z,
  ];
}

const fromLAB = (l: number, a: number, b: number) =>
  fromLinearRGB(labToLinear(l, a, b));

function toOKLAB(colour: Rgb) {
  const [r, g, b] = linear(colour);
  const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return {
    l: 0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
    a: 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
    b: 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s,
  };
}

/** Linear sRGB of an OKLab colour, unclamped. */
export function oklabToLinear(l: number, a: number, b: number): Vec3 {
  const l_ = (l + 0.3963377774 * a + 0.2158037573 * b) ** 3;
  const m_ = (l - 0.1055613458 * a - 0.0638541728 * b) ** 3;
  const s_ = (l - 0.0894841775 * a - 1.291485548 * b) ** 3;
  return [
    4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_,
    -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_,
    -0.0041960863 * l_ - 0.7034186147 * m_ + 1.707614701 * s_,
  ];
}

const fromOKLAB = (l: number, a: number, b: number) =>
  fromLinearRGB(oklabToLinear(l, a, b));

function polar(lab: { l: number; a: number; b: number }) {
  let h = (Math.atan2(lab.b, lab.a) * 180) / Math.PI;
  if (h < 0) h += 360;
  return { l: lab.l, c: Math.hypot(lab.a, lab.b), h };
}

const fromOKLCH = (l: number, c: number, h: number) =>
  fromOKLAB(
    l,
    c * Math.cos((h * Math.PI) / 180),
    c * Math.sin((h * Math.PI) / 180),
  );

const fromLCH = (l: number, c: number, h: number) =>
  fromLAB(
    l,
    c * Math.cos((h * Math.PI) / 180),
    c * Math.sin((h * Math.PI) / 180),
  );
