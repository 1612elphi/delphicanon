import { nearSurface, steps, substeps, wedge } from './geometry.ts';
import { labReach, oklabReach } from './space.ts';

const float = (n: number) => (Number.isInteger(n) ? `${n}.0` : String(n));

/** Slots of the `u` uniform array, as the Metal `SolidUniforms` fields. */
export const uniformCount = 13;

const vertex = `#version 300 es
void main() {
  vec2 corner = vec2(float((gl_VertexID << 1) & 2), float(gl_VertexID & 2));
  gl_Position = vec4(corner * 2.0 - 1.0, 0.0, 1.0);
}`;

/** Mirrors `Geometry` and `Sheet`: change both together. */
const fragment = `#version 300 es
precision highp float;
precision highp int;

uniform vec4 u[${uniformCount}];
out vec4 outColour;

#define U_CAMERA u[0]
#define U_RIGHT u[1]
#define U_UP u[2]
#define U_FORWARD u[3]
#define U_PICK u[4]
#define U_CUT u[5]
#define U_PARAMS u[6]
#define U_SLICE u[7]
#define U_TURN u[8]
#define U_CENTRE u[9]

const float PI = 3.14159265358979;
const float oklabReach = ${float(oklabReach)};
const float labReach = ${float(labReach)};
const float wedge = ${float(wedge)};
const int steps = ${steps};
const int substeps = ${substeps};
const float nearSurface = ${float(nearSurface)};

float max3(vec3 v) { return max(v.x, max(v.y, v.z)); }
float min3(vec3 v) { return min(v.x, min(v.y, v.z)); }

vec3 oklabToLinear(vec3 lab) {
  float l = lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z;
  float m = lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z;
  float s = lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z;
  l = l * l * l; m = m * m * m; s = s * s * s;
  return vec3(
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s);
}

float labInverse(float t) {
  return t > 6.0 / 29.0 ? t * t * t : 3.0 * (6.0 / 29.0) * (6.0 / 29.0) * (t - 4.0 / 29.0);
}

vec3 labToLinear(vec3 lab) {
  float fy = (lab.x + 16.0) / 116.0;
  vec3 xyz = vec3(0.95047 * labInverse(fy + lab.y / 500.0), labInverse(fy), 1.08883 * labInverse(fy - lab.z / 200.0));
  return vec3(
    3.2404542 * xyz.x - 1.5371385 * xyz.y - 0.4985314 * xyz.z,
    -0.9692660 * xyz.x + 1.8760108 * xyz.y + 0.0415560 * xyz.z,
    0.0556434 * xyz.x - 0.2040259 * xyz.y + 1.0572252 * xyz.z);
}

vec3 linearToSRGB(vec3 c) {
  c = clamp(c, 0.0, 1.0);
  return mix(1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, 12.92 * c, lessThanEqual(c, vec3(0.0031308)));
}

vec3 hueRGB(float h) {
  return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

bool isCartesian(int space) { return space <= 1 || space >= 5; }

vec3 channels(vec3 p, int space, float size) {
  if (isCartesian(space)) return (p / size + 1.0) * 0.5;
  float hue = atan(p.z, p.x) / (2.0 * PI);
  return vec3(hue < 0.0 ? hue + 1.0 : hue, length(p.xz), (p.y + 1.0) * 0.5);
}

vec3 linearAt(vec3 p, int space) {
  if (space == 3 || space == 5) return oklabToLinear(vec3((p.y + 1.0) * 0.5, p.x * oklabReach, p.z * oklabReach));
  return labToLinear(vec3((p.y + 1.0) * 50.0, p.x * labReach, p.z * labReach));
}

vec3 trueColourAt(vec3 p) {
  int space = int(U_PARAMS.x);
  vec3 c = clamp(channels(p, space, U_SLICE.z), 0.0, 1.0);
  if (space == 0) return c;
  if (space == 1) {
    float chroma = (1.0 - abs(2.0 * c.y - 1.0)) * c.z;
    return (hueRGB(c.x) - 0.5) * chroma + c.y;
  }
  if (space == 2) return c.z * (1.0 - c.y + c.y * hueRGB(c.x));
  if (space == 7) return (1.0 - c) * (1.0 - U_PICK.w);
  return linearToSRGB(linearAt(p, space));
}

vec3 colourAt(vec3 p) {
  vec3 c = trueColourAt(p);
  return clamp(vec3(dot(u[10].xyz, c), dot(u[11].xyz, c), dot(u[12].xyz, c)), 0.0, 1.0);
}

float shape(vec3 p, int space, float size) {
  float box = max3(abs(p)) - size;
  if (space <= 1 || space == 7) return box;
  float cylinder = max(length(p.xz) - 1.0, abs(p.y) - 1.0);
  if (space == 2) return cylinder;
  vec3 c = linearAt(p, space);
  return max(box, max(max3(c - 1.0), max3(-c)));
}

float cutAway(vec3 p) {
  int space = int(U_PARAMS.x);
  vec3 c = channels(p, space, U_SLICE.z);
  if (isCartesian(space)) return min3((c - U_PICK.xyz) * U_CUT.xyz);
  float turn = fract(U_CUT.x > 0.0 ? c.x - U_PICK.x : U_PICK.x - c.x);
  float around = min(turn, wedge - turn);
  return min(around, min(c.y - U_PICK.y, (c.z - U_PICK.z) * U_CUT.z));
}

float solid(vec3 p) {
  float inside = shape(p, int(U_PARAMS.x), U_SLICE.z);
  return U_CUT.w > 0.0 ? max(inside, cutAway(p)) : inside;
}

float planeHit(vec3 o, vec3 d, int index, float at) {
  return abs(d[index]) < 1e-6 ? -1.0 : (at - o[index]) / d[index];
}

float sliceHit(vec3 o, vec3 d, int axis, float reach) {
  int space = int(U_PARAMS.x);
  vec3 centre = U_CENTRE.xyz;
  float value = U_PICK[axis];
  float hits[2] = float[2](-1.0, -1.0);
  if (isCartesian(space)) {
    hits[0] = planeHit(o, d, axis, (value * 2.0 - 1.0) * U_SLICE.z);
  } else if (axis == 2) {
    hits[0] = planeHit(o, d, 1, value * 2.0 - 1.0);
  } else if (axis == 0) {
    float angle = value * 2.0 * PI;
    vec3 normal = vec3(-sin(angle), 0.0, cos(angle));
    float facing = dot(d, normal);
    if (abs(facing) > 1e-6) {
      float t = -dot(o, normal) / facing;
      vec3 p = o + d * t;
      hits[0] = dot(p.xz, vec2(cos(angle), sin(angle))) >= 0.0 ? t : -1.0;
    }
  } else {
    float a = dot(d.xz, d.xz);
    float b = 2.0 * dot(o.xz, d.xz);
    float c = dot(o.xz, o.xz) - value * value;
    float root = b * b - 4.0 * a * c;
    if (a > 1e-9 && root >= 0.0) {
      hits[0] = (-b - sqrt(root)) / (2.0 * a);
      hits[1] = (-b + sqrt(root)) / (2.0 * a);
    }
  }
  for (int i = 0; i < 2; i++) {
    vec3 p = o + d * hits[i];
    if (hits[i] > 0.0 && shape(p, space, U_SLICE.z) <= 1e-4 && distance(p, centre) <= reach) return hits[i];
  }
  return -1.0;
}

bool unrolledHit(vec3 o, vec3 d, out vec3 original) {
  original = vec3(0.0);
  float r = U_PICK.y;
  float facing = U_TURN.w;
  float bend = 1.0 - U_SLICE.w;
  vec3 normal = vec3(cos(facing), 0.0, sin(facing));
  vec3 tangent = vec3(-sin(facing), 0.0, cos(facing));
  float facingRay = dot(d, normal);
  if (abs(facingRay) < 1e-6 || r < 1e-4) return false;
  vec3 p = o + d * (dot(normal * r - o, normal) / facingRay);
  float along = dot(p, tangent);
  float bent = along * bend / r;
  if (abs(bent) > 1.0) return false;
  float front = asin(bent);
  float angles[2] = float[2](front, (front < 0.0 ? -PI : PI) - front);
  int count = bend > 1e-4 ? 2 : 1;
  for (int i = 0; i < count; i++) {
    float turn = bend > 1e-4 ? angles[i] / bend : along / r;
    if (abs(turn) > PI) continue;
    original = vec3(r * cos(facing + turn), p.y, r * sin(facing + turn));
    if (shape(original, int(U_PARAMS.x), U_SLICE.z) <= 1e-4) return true;
  }
  return false;
}

float slicesHit(vec3 o, vec3 d) {
  float at = sliceHit(o, d, int(U_SLICE.x), U_TURN.y);
  if (U_TURN.x >= 0.0) {
    float old = sliceHit(o, d, int(U_TURN.x), U_TURN.z);
    if (old > 0.0 && (at < 0.0 || old < at)) at = old;
  }
  return at;
}

void main() {
  vec2 ndc = gl_FragCoord.xy / U_PARAMS.zw * 2.0 - 1.0;
  vec3 origin = U_CAMERA.xyz;
  vec3 ray = normalize(U_FORWARD.xyz + ndc.x * U_RIGHT.w * U_RIGHT.xyz + ndc.y * U_UP.w * U_UP.xyz);

  // sheet exceeds unit box
  if (U_SLICE.w > 0.0) {
    vec3 original;
    outColour = unrolledHit(origin, ray, original) ? vec4(colourAt(original), 1.0) : vec4(0.0);
    return;
  }

  // glsl es: x / 0 undefined
  vec3 safe = mix(ray, vec3(1e-20), equal(ray, vec3(0.0)));
  vec3 a = (-1.001 - origin) / safe;
  vec3 b = (1.001 - origin) / safe;
  float near = max3(min(a, b));
  float far = min3(max(a, b));
  if (far < max(near, 0.0)) { outColour = vec4(0.0); return; }

  if (U_SLICE.x >= 0.0 && U_SLICE.y <= 0.0) {
    float at = slicesHit(origin, ray);
    outColour = at < 0.0 ? vec4(0.0) : vec4(colourAt(origin + ray * at), 1.0);
    return;
  }

  float stride = (far - near) / float(steps);
  float previous = near;
  float t = near;
  bool hit = false;
  for (int i = 0; i <= steps && !hit; i++) {
    t = near + stride * float(i);
    float value = solid(origin + ray * t);
    if (value < 0.0) { hit = true; break; }
    // catch grazing slivers
    if (value < nearSurface && i < steps) {
      for (int j = 1; j < substeps; j++) {
        float fine = t + stride * float(j) / float(substeps);
        if (solid(origin + ray * fine) < 0.0) {
          previous = fine - stride / float(substeps);
          t = fine;
          hit = true;
          break;
        }
      }
    }
    if (!hit) previous = t;
  }
  if (!hit) { outColour = vec4(0.0); return; }
  if (t > near) {
    float lo = previous, hi = t;
    for (int i = 0; i < 10; i++) {
      float mid = (lo + hi) * 0.5;
      if (solid(origin + ray * mid) < 0.0) hi = mid; else lo = mid;
    }
    t = hi;
  }

  vec3 p = origin + ray * t;
  float e = 0.002;
  vec3 normal = normalize(vec3(
    solid(p + vec3(e, 0.0, 0.0)) - solid(p - vec3(e, 0.0, 0.0)),
    solid(p + vec3(0.0, e, 0.0)) - solid(p - vec3(0.0, e, 0.0)),
    solid(p + vec3(0.0, 0.0, e)) - solid(p - vec3(0.0, 0.0, e))));
  vec3 light = normalize(U_UP.xyz * 0.8 - U_RIGHT.xyz * 0.5 - U_FORWARD.xyz);
  float lit = max(dot(normal, light), 0.0);
  vec3 colour = colourAt(p) * (1.0 - U_PARAMS.y * (1.0 - lit));
  if (U_SLICE.x < 0.0) { outColour = vec4(colour, 1.0); return; }

  // premultiplied ghost over slice
  vec4 ghost = vec4(colour * U_SLICE.y, U_SLICE.y);
  float at = slicesHit(origin, ray);
  if (at < 0.0) { outColour = ghost; return; }
  outColour = vec4(colourAt(origin + ray * at) * (1.0 - ghost.a) + ghost.rgb, 1.0);
}`;

export interface Renderer {
  draw(uniforms: Float32Array, width: number, height: number): void;
  destroy(): void;
}

/** Undefined without WebGL2 or when the shader fails to compile. */
export function createRenderer(
  canvas: HTMLCanvasElement,
): Renderer | undefined {
  // preserved so tests and screenshots can read pixels between draws
  const gl = canvas.getContext('webgl2', {
    premultipliedAlpha: true,
    alpha: true,
    antialias: false,
    preserveDrawingBuffer: true,
  });
  if (!gl) return undefined;
  const program = gl.createProgram();
  for (const [type, source] of [
    [gl.VERTEX_SHADER, vertex],
    [gl.FRAGMENT_SHADER, fragment],
  ] as const) {
    const shader = gl.createShader(type)!;
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS))
      console.error('colour solid shader', gl.getShaderInfoLog(shader));
    gl.attachShader(program, shader);
    gl.deleteShader(shader);
  }
  gl.linkProgram(program);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    console.error('colour solid shader', gl.getProgramInfoLog(program));
    gl.deleteProgram(program);
    gl.getExtension('WEBGL_lose_context')?.loseContext();
    return undefined;
  }
  const slot = gl.getUniformLocation(program, 'u');
  return {
    draw(uniforms, width, height) {
      gl.viewport(0, 0, width, height);
      gl.clearColor(0, 0, 0, 0);
      gl.clear(gl.COLOR_BUFFER_BIT);
      gl.useProgram(program);
      gl.uniform4fv(slot, uniforms);
      gl.drawArrays(gl.TRIANGLES, 0, 3);
    },
    destroy() {
      gl.deleteProgram(program);
      gl.getExtension('WEBGL_lose_context')?.loseContext();
    },
  };
}
