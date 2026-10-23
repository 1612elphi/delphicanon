import { labToLinear, oklabToLinear } from '../colour.ts';
import {
	isCartesian,
	labReach,
	oklabReach,
	type SolidSpace as Space,
} from '../colour-space.ts';
import { add, dot, scale, sub, type Vec3, type Vec4 } from './vec.ts';

/** Share of a turn the cut takes out of a cylinder. */
export const wedge = 0.25;
export const steps = 128;
/** A sample closer to the surface than this gets `substeps` finer samples before the next one. */
export const nearSurface = 0.04;
export const substeps = 8;
/** Half-size of the CMYK box at 100 % black; 1 at 0 %. */
export const innerSize = 0.36;

/** Linear sRGB at a point of the OKLab or CIELAB box, unclamped, as the shader's `linearAt`. */
export function linearAt(p: Vec3, space: Space): Vec3 {
	if (space === 'oklch' || space === 'oklab') {
		return oklabToLinear(
			(p[1] + 1) / 2,
			p[0] * oklabReach,
			p[2] * oklabReach,
		);
	}
	return labToLinear((p[1] + 1) * 50, p[0] * labReach, p[2] * labReach);
}

/** The solid in its box, x y z each -1...1, y up. Mirrors the fragment shader: change both together. */
export class Geometry {
	readonly space: Space;
	/** Channels along x y z. */
	readonly pick: Vec3;
	readonly cut: Vec4;
	readonly slice: number | null;
	/** CMYK's black; 0 in every other space. */
	readonly black: number;

	constructor(
		space: Space,
		pick: Vec3,
		cut: Vec4 = [0, 0, 0, 0],
		slice: number | null = null,
		black = 0,
	) {
		this.space = space;
		this.pick = pick;
		this.cut = cut;
		this.slice = slice;
		this.black = black;
	}

	/** Half-size of the box. */
	get size() {
		return 1 - this.black * (1 - innerSize);
	}

	channels(p: Vec3): Vec3 {
		if (isCartesian(this.space)) {
			return p.map((v) => (v / this.size + 1) / 2) as Vec3;
		}
		const hue = Math.atan2(p[2], p[0]) / (2 * Math.PI);
		return [
			hue < 0 ? hue + 1 : hue,
			Math.hypot(p[0], p[2]),
			(p[1] + 1) / 2,
		];
	}

	display(channels: Vec3): Vec3 {
		if (isCartesian(this.space)) {
			return channels.map(
				(v) => (v * 2 - 1) * this.size,
			) as Vec3;
		}
		const angle = channels[0] * 2 * Math.PI;
		return [
			channels[1] * Math.cos(angle),
			channels[2] * 2 - 1,
			channels[1] * Math.sin(angle),
		];
	}

	/** Negative inside. */
	shape(p: Vec3): number {
		const box = Math.max(...p.map(Math.abs)) - this.size;
		const space = this.space;
		if (space === 'rgb' || space === 'hsl' || space === 'cmyk')
			return box;
		const cylinder = Math.max(
			Math.hypot(p[0], p[2]) - 1,
			Math.abs(p[1]) - 1,
		);
		if (space === 'hsb') return cylinder;
		const c = linearAt(p, space);
		return Math.max(
			box,
			Math.max(...c.map((v) => v - 1)),
			Math.max(...c.map((v) => -v)),
		);
	}

	/** Positive inside the cut. */
	cutAway(p: Vec3): number {
		const c = this.channels(p);
		const { pick, cut } = this;
		if (isCartesian(this.space)) {
			return Math.min(
				...c.map((v, i) => (v - pick[i]!) * cut[i]!),
			);
		}
		let turn = cut[0] > 0 ? c[0] - pick[0] : pick[0] - c[0];
		turn -= Math.floor(turn);
		return Math.min(
			Math.min(turn, wedge - turn),
			Math.min(c[1] - pick[1], (c[2] - pick[2]) * cut[2]),
		);
	}

	/** Negative inside. */
	solid(p: Vec3): number {
		const inside = this.shape(p);
		return this.cut[3] > 0
			? Math.max(inside, this.cutAway(p))
			: inside;
	}

	/** Distance along `ray` to the slice where it is inside the solid. */
	sliceHit(o: Vec3, d: Vec3): number | undefined {
		const { slice } = this;
		if (slice === null) return undefined;
		const value = this.pick[slice]!;
		let hits: number[] = [];
		if (isCartesian(this.space)) {
			hits = [
				planeHit(
					o,
					d,
					slice,
					(value * 2 - 1) * this.size,
				),
			];
		} else if (slice === 2) {
			hits = [planeHit(o, d, 1, value * 2 - 1)];
		} else if (slice === 0) {
			const angle = value * 2 * Math.PI;
			const normal: Vec3 = [
				-Math.sin(angle),
				0,
				Math.cos(angle),
			];
			const facing = dot(d, normal);
			if (Math.abs(facing) > 1e-9) {
				const t = -dot(o, normal) / facing;
				const p = add(o, scale(d, t));
				if (
					p[0] * Math.cos(angle) +
						p[2] * Math.sin(angle) >=
					0
				)
					hits = [t];
			}
		} else {
			const a = d[0] * d[0] + d[2] * d[2];
			const b = 2 * (o[0] * d[0] + o[2] * d[2]);
			const c = o[0] * o[0] + o[2] * o[2] - value * value;
			const root = b * b - 4 * a * c;
			if (a > 1e-12 && root >= 0) {
				hits = [
					(-b - Math.sqrt(root)) / (2 * a),
					(-b + Math.sqrt(root)) / (2 * a),
				];
			}
		}
		return hits.find(
			(t) => t > 0 && this.shape(add(o, scale(d, t))) <= 1e-4,
		);
	}
}

function planeHit(o: Vec3, d: Vec3, index: number, at: number) {
	return Math.abs(d[index]!) < 1e-9 ? -1 : (at - o[index]!) / d[index]!;
}

/** Distance along `ray` to the first point inside the solid. */
export function march(
	origin: Vec3,
	ray: Vec3,
	geometry: Geometry,
): number | undefined {
	const a = origin.map((o, i) => (-1.001 - o) / ray[i]!);
	const b = origin.map((o, i) => (1.001 - o) / ray[i]!);
	const near = Math.max(...a.map((v, i) => Math.min(v, b[i]!)));
	const far = Math.min(...a.map((v, i) => Math.max(v, b[i]!)));
	if (!(far >= Math.max(near, 0))) return undefined;
	const step = (far - near) / steps;
	const at = (t: number) => geometry.solid(add(origin, scale(ray, t)));
	const refine = (lo: number, hi: number) => {
		for (let i = 0; i < 10; i++) {
			const mid = (lo + hi) / 2;
			if (at(mid) < 0) hi = mid;
			else lo = mid;
		}
		return hi;
	};
	let previous = near;
	for (let index = 0; index <= steps; index++) {
		const t = near + step * index;
		const value = at(t);
		if (value < 0) return index === 0 ? t : refine(previous, t);
		if (value < nearSurface && index < steps) {
			for (let sub = 1; sub < substeps; sub++) {
				const fine = t + (step * sub) / substeps;
				if (at(fine) < 0)
					return refine(
						fine - step / substeps,
						fine,
					);
			}
		}
		previous = t;
	}
	return undefined;
}

/**
 * A shell unrolled about the line facing the camera, lengths kept: an arc of
 * radius `radius / bend` through the shell's front line, flat at `bend` 0.
 * Mirrors `unrolledHit` in the fragment shader: change both together.
 */
export class Sheet {
	readonly radius: number;
	readonly facing: number;
	readonly bend: number;

	constructor(radius: number, facing: number, bend: number) {
		this.radius = radius;
		this.facing = facing;
		this.bend = bend;
	}

	get normal(): Vec3 {
		return [Math.cos(this.facing), 0, Math.sin(this.facing)];
	}

	get tangent(): Vec3 {
		return [-Math.sin(this.facing), 0, Math.cos(this.facing)];
	}

	/** The sheet point of the shell point `turn` radians round from the facing hue, and whether it is on the far side. */
	place(turn: number, y: number): { point: Vec3; far: boolean } {
		const { radius, bend } = this;
		const angle = turn * bend;
		const along =
			bend > 1e-4
				? (radius * Math.sin(angle)) / bend
				: radius * turn;
		const sag =
			bend > 1e-4
				? (radius * (1 - Math.cos(angle))) / bend
				: 0;
		return {
			point: add(
				add(
					scale(this.normal, radius - sag),
					scale(this.tangent, along),
				),
				[0, y, 0],
			),
			far: Math.abs(angle) > Math.PI / 2,
		};
	}

	/** Shell points whose sheet points lie under the ray, near side first. Assumes the camera faces the sheet head on. */
	shellPoints(origin: Vec3, ray: Vec3): Vec3[] {
		const { radius, bend, facing, normal } = this;
		const facingRay = dot(ray, normal);
		if (Math.abs(facingRay) <= 1e-9 || radius <= 1e-4) return [];
		const p = add(
			origin,
			scale(
				ray,
				dot(
					sub(scale(normal, radius), origin),
					normal,
				) / facingRay,
			),
		);
		const along = dot(p, this.tangent);
		const bent = (along * bend) / radius;
		if (Math.abs(bent) > 1) return [];
		const front = Math.asin(bent);
		const turns =
			bend > 1e-4
				? [
						front,
						(front < 0
							? -Math.PI
							: Math.PI) - front,
					].map((a) => a / bend)
				: [along / radius];
		return turns
			.filter((t) => Math.abs(t) <= Math.PI)
			.map((t) => [
				radius * Math.cos(facing + t),
				p[1],
				radius * Math.sin(facing + t),
			]);
	}
}
