import { module, test } from 'qunit';
import {
	Geometry,
	innerSize,
	march,
	Sheet,
} from '#src/lib/colour-solid/geometry.ts';
import { SolidState } from '#src/lib/colour-solid/solid.ts';
import type { Rgb } from '#src/lib/colour.ts';
import {
	colourAt,
	convertPoint,
	pointFor,
	solidSpaces,
} from '#src/lib/colour-space.ts';
import { camera, project, ray } from '#src/lib/colour-solid/view.ts';
import {
	length,
	normalize,
	sub,
	xyz,
	type Vec3,
} from '#src/lib/colour-solid/vec.ts';

const samples: Rgb[] = [
	[0.12, 0.4, 0.15],
	[0.9, 0.3, 0.6],
	[0.2, 0.5, 0.95],
];

const near = (a: Vec3, b: Vec3, within = 1e-9) => length(sub(a, b)) < within;

module('Unit | lib/colour-solid', function () {
	test('every space round-trips a colour and its point', function (assert) {
		for (const space of solidSpaces) {
			for (const sample of samples) {
				const point = pointFor(space, sample);
				const back = colourAt(space, point);
				assert.true(
					Math.abs(back[0] - sample[0]) +
						Math.abs(back[1] - sample[1]) +
						Math.abs(back[2] - sample[2]) <
						0.01,
					`${space} colour`,
				);
				const geometry = new Geometry(
					space,
					[0, 0, 0],
					undefined,
					null,
					point[3],
				);
				const channels = xyz(point);
				assert.true(
					near(
						geometry.channels(
							geometry.display(
								channels,
							),
						),
						channels,
					),
					`${space} display`,
				);
			}
		}
		assert.deepEqual(pointFor('cmyk', [0, 0, 0]), [0, 0, 0, 1]);
		const moved = convertPoint('rgb', 'hsl', [1, 0, 0, 0]);
		assert.deepEqual(
			moved,
			[0, 0.5, 1, 0],
			'red is hue 0, half light, full',
		);
	});

	test('march meets the faces and the cut', function (assert) {
		const flat = new Geometry('rgb', [0.5, 0.5, 0.5]);
		const t = march([0, 0, 6], [0, 0, -1], flat);
		assert.true(Math.abs(t! - 5) < 0.01, 'front face of the cube');
		const cut = new Geometry('rgb', [0.5, 0.5, 0.5], [1, 1, 1, 1]);
		const corner = march([4, 4, 4], normalize([-1, -1, -1]), cut);
		assert.true(
			Math.abs(corner! - Math.sqrt(48)) < 0.02,
			'cut reaches the centre',
		);
		const gamut = new Geometry('oklch', [0, 0, 0]);
		assert.true(
			gamut.shape([0, 0, 0]) < 0 &&
				gamut.shape([0.95, 0, 0.95]) > 0,
		);
		const deep = new Geometry(
			'cmyk',
			[0, 0, 0],
			undefined,
			null,
			1,
		);
		assert.true(Math.abs(deep.size - innerSize) < 1e-12);
		assert.true(
			deep.shape([0.5, 0, 0]) > 0,
			'full ink shrinks to the inner cube',
		);
	});

	test('slices: plane, hue half-plane, shell', function (assert) {
		const plane = new Geometry(
			'cmyk',
			[1, 0.5, 0.5],
			undefined,
			0,
			1,
		);
		assert.true(
			Math.abs(
				plane.sliceHit([6, 0, 0], [-1, 0, 0])! -
					(6 - innerSize),
			) < 1e-9,
			'cmyk plane follows the box',
		);
		const leaf = new Geometry(
			'hsb',
			[0.25, 0.5, 0.5],
			undefined,
			0,
		);
		assert.true(
			Math.abs(leaf.sliceHit([6, 0, 0.5], [-1, 0, 0])! - 6) <
				1e-9,
		);
		assert.strictEqual(
			leaf.sliceHit([6, 0, -0.5], [-1, 0, 0]),
			undefined,
			'opposite half is empty',
		);
		const shell = new Geometry('hsb', [0, 0.5, 0.5], undefined, 1);
		assert.true(
			Math.abs(shell.sliceHit([6, 0, 0], [-1, 0, 0])! - 5.5) <
				1e-9,
			'near side of the shell',
		);
		const disc = new Geometry('hsb', [0, 0.5, 0.75], undefined, 2);
		assert.true(
			Math.abs(disc.sliceHit([0, 6, 0], [0, -1, 0])! - 5.5) <
				1e-9,
		);
	});

	test('unroll keeps arc lengths and maps back to the shell', function (assert) {
		const rolled = new Sheet(0.5, 0.3, 1).place(1, 0.2).point;
		assert.true(
			near(rolled, [
				0.5 * Math.cos(1.3),
				0.2,
				0.5 * Math.sin(1.3),
			]),
		);
		const flat = new Sheet(0.5, 0, 0);
		assert.true(
			near(flat.place(2, 0).point, [0.5, 0, 1]),
			'flat keeps arc length',
		);
		assert.false(
			flat.place(3, 0).far,
			'a flat sheet has no far side',
		);
		assert.true(
			new Sheet(0.5, 0, 1).place(2, 0).far,
			'rolled, past a quarter turn is the far side',
		);
		const under = flat.shellPoints([80, 0.1, 1], [-1, 0, 0]);
		assert.strictEqual(under.length, 1);
		assert.true(
			near(under[0]!, [
				0.5 * Math.cos(2),
				0.1,
				0.5 * Math.sin(2),
			]),
		);
		const half = new Sheet(0.5, 0.3, 0.5);
		const bent = half.place(0.8, 0).point;
		const origin: Vec3 = [
			bent[0] + half.normal[0] * 80,
			bent[1],
			bent[2] + half.normal[2] * 80,
		];
		const back = half.shellPoints(origin, [
			-half.normal[0],
			0,
			-half.normal[2],
		]);
		assert.true(
			near(
				back[0]!,
				[0.5 * Math.cos(1.1), 0, 0.5 * Math.sin(1.1)],
				1e-6,
			),
			'bent sheet round trip',
		);
	});

	test('projection and ray agree', function (assert) {
		const size = { width: 300, height: 200 };
		const cam = camera(
			{
				yaw: 0.62,
				pitch: 0.42,
				distance: 6,
				fit: Math.sqrt(3),
				lookAt: [0, 0, 0],
			},
			size,
		);
		const centre = project(cam, size, [0, 0, 0])!;
		assert.true(
			Math.abs(centre.x - 150) < 1e-9 &&
				Math.abs(centre.y - 100) < 1e-9,
		);
		const p: Vec3 = [0.4, -0.3, 0.7];
		const at = project(cam, size, p)!;
		const through = ray(cam, size, at);
		assert.true(
			near(through, normalize(sub(p, cam.position)), 1e-9),
		);
		assert.strictEqual(
			project(cam, size, cam.position),
			undefined,
			'behind',
		);
	});

	test('a tap picks the face under it; a slice keeps its channel', function (assert) {
		const state = new SolidState(
			'rgb',
			[0.5, 0.5, 0.5, 0],
			() => {},
		);
		state.animates = false;
		state.size = { width: 400, height: 400 };
		state.setCutsAway(false);
		assert.true(
			state.pick({ x: 200, y: 200 }),
			'the centre hits the cube',
		);
		const corner = state.point;
		assert.true(
			corner.slice(0, 3).some((v) => v > 0.99),
			'a face of the cube is a channel at its maximum',
		);
		assert.false(state.pick({ x: 2, y: 2 }), 'the corner misses');
		state.setSliceAxis(0);
		const red = state.point[0];
		state.pick({ x: 210, y: 190 });
		assert.strictEqual(
			state.point[0],
			red,
			'the sliced channel holds',
		);
	});

	test('ortho on a shell unrolls it; leaving rolls it up', function (assert) {
		const state = new SolidState(
			'hsb',
			[0.1, 0.6, 0.5, 0],
			() => {},
		);
		state.animates = false;
		state.size = { width: 400, height: 400 };
		state.setSliceAxis(1);
		state.setOrtho(true);
		assert.ok(state.sheet, 'flat sheet');
		assert.strictEqual(state.sheet!.bend, 0);
		assert.true(state.pick({ x: 200, y: 200 }), 'the sheet picks');
		assert.strictEqual(state.point[1], 0.6, 'on the shell');
		state.setOrtho(false);
		assert.strictEqual(state.sheet, undefined, 'rolled');
	});

	test('animations advance and stop', function (assert) {
		const state = new SolidState(
			'hsb',
			[0.9, 0.5, 0.5, 0],
			() => {},
		);
		state.setPoint([0.1, 0.5, 0.5, 0], true);
		state.tick(0.125);
		assert.true(
			state.shown[0] > 0.9,
			'hue eases the short way, past 1',
		);
		state.tick(1);
		assert.deepEqual(state.shown, [0.1, 0.5, 0.5, 0]);
		state.setVision(
			[
				[0, 0, 0],
				[0, 0, 0],
				[0, 0, 0],
			],
			true,
		);
		state.tick(1);
		assert.deepEqual(state.seen([1, 1, 1]), [0, 0, 0]);
		assert.false(state.animating);
	});
});
