import { module, test } from 'qunit';
import {
	cmyk,
	contrastFigure,
	contrastRatio,
	formatColour,
	fromHsb,
	fromHsl,
	hex,
	hsb,
	hsl,
	lab,
	lch,
	oklab,
	oklch,
	parseColour,
	parseHex,
	takesBlackInk,
	type Rgb,
} from '#src/lib/colour.ts';
import {
	channels,
	colourAt,
	pointFor,
	solidSpaces,
} from '#src/lib/colour-space.ts';

const red: Rgb = [1, 0, 0];
const blue = parseHex('#3B82F6')!;

function close(
	assert: Assert,
	actual: readonly number[],
	expected: readonly number[],
	tolerance: number,
	message?: string,
) {
	const ok = actual.every(
		(v, i) => Math.abs(v - (expected[i] ?? NaN)) <= tolerance,
	);
	assert.true(
		ok,
		`${message ?? ''} ${actual.map((v) => v.toFixed(4)).join(' ')} ~ ${expected.join(' ')}`,
	);
}

module('Unit | lib/colour', function () {
	test('hex parses and formats', function (assert) {
		assert.strictEqual(hex(blue), '#3B82F6');
		assert.strictEqual(hex(parseHex('f0a')!), '#FF00AA');
		assert.strictEqual(hex([1.2, -0.1, 0.5]), '#FF0080', 'clamps');
		assert.strictEqual(parseHex('#12345'), undefined);
		assert.strictEqual(parseHex('ggg'), undefined);
	});

	test('hsl and hsb', function (assert) {
		close(assert, hsl(blue), [217.2, 91.2, 59.8], 0.1);
		close(assert, hsl([0.5, 0.5, 0.5]), [0, 0, 50], 1e-9, 'grey');
		close(assert, fromHsl(217.22, 91.22, 59.8), blue, 0.002);
		close(assert, hsb(blue), [217.22, 0.7602, 0.9647], 0.005);
		close(assert, fromHsb(...hsb(blue)), blue, 1e-9);
	});

	test('lab, lch, oklab and oklch against published values', function (assert) {
		close(assert, lab(red), [53.24, 80.09, 67.2], 0.01);
		close(assert, lch(red), [53.24, 104.55, 39.99], 0.01);
		close(assert, oklab(red), [0.628, 0.2249, 0.1258], 0.0002);
		close(assert, oklch(red), [0.628, 0.2577, 29.23], 0.01);
		close(assert, oklab([1, 1, 1]), [1, 0, 0], 1e-4, 'white');
		close(assert, lab([1, 1, 1]), [100, 0, 0], 0.01, 'white');
	});

	test('naive cmyk', function (assert) {
		close(assert, cmyk(red), [0, 1, 1, 0], 1e-9);
		close(assert, cmyk([0, 0, 0]), [0, 0, 0, 1], 1e-9);
		close(assert, cmyk([0.5, 0.25, 0.5]), [0, 0.5, 0, 0.5], 1e-9);
	});

	test('WCAG contrast', function (assert) {
		assert.strictEqual(contrastRatio([0, 0, 0], [1, 1, 1]), 21);
		close(
			assert,
			[contrastRatio(parseHex('777777')!, [1, 1, 1])],
			[4.48],
			0.005,
		);
		assert.strictEqual(
			contrastFigure(4.499),
			'4.49',
			'never rounds up',
		);
		assert.strictEqual(contrastFigure(4.5), '4.5');
		assert.strictEqual(contrastFigure(21), '21');
		assert.true(takesBlackInk([1, 1, 0]));
		assert.false(takesBlackInk([0, 0, 0.5]));
	});

	test('formats as DelphiCore does', function (assert) {
		assert.strictEqual(
			formatColour(blue, 'rgb'),
			'rgb(59, 130, 246)',
		);
		assert.strictEqual(
			formatColour(blue, 'hsl'),
			'hsl(217, 91%, 60%)',
		);
		assert.strictEqual(
			formatColour(red, 'lab'),
			'lab(53.2 80.1 67.2)',
		);
		assert.strictEqual(
			formatColour(red, 'oklch'),
			'oklch(0.6280 0.2577 29.2)',
		);
	});

	test('parses any notation', function (assert) {
		assert.strictEqual(
			hex(parseColour(' rgb(59, 130, 246) ')!),
			'#3B82F6',
		);
		assert.strictEqual(
			hex(parseColour('hsl(0, 100%, 50%)')!),
			'#FF0000',
		);
		assert.strictEqual(
			hex(parseColour('oklch(0.628 0.2577 29.23)')!),
			'#FF0000',
		);
		assert.strictEqual(
			hex(parseColour('LAB(53.24 80.09 67.2)')!),
			'#FF0000',
		);
		assert.strictEqual(hex(parseColour('3b82f6')!), '#3B82F6');
		assert.strictEqual(parseColour('hsl(nan, 1, 1)'), undefined);
		assert.strictEqual(parseColour('rgb(1, 2)'), undefined);
		assert.strictEqual(parseColour('blue'), undefined);
	});

	test('every solid space round-trips a colour', function (assert) {
		for (const space of solidSpaces) {
			close(
				assert,
				colourAt(space, pointFor(space, blue)),
				blue,
				1e-6,
				space,
			);
			const top = channels(space).map(
				(c) => c.min + (c.max - c.min) / 2,
			);
			assert.strictEqual(
				top.length,
				space === 'cmyk' ? 4 : 3,
				space,
			);
		}
		close(
			assert,
			pointFor('hsl', blue),
			[217.2 / 360, 0.598, 0.912, 0],
			0.001,
		);
	});
});
